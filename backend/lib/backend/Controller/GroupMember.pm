package backend::Controller::GroupMember;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use YAML::XS 'LoadFile';

sub getGroupMembers {
    my $c = shift;

    # Get group_id from URL parameter
    my $group_id = $c->stash('group_id');

    # Get the username from the session
    my $username = $c->session('login_name');

    unless ($username) {
        return $c->render(
            json => {error => 'User not authenticated'},
            status => 401
        );
    }

    # Load database configuration
    my $config = eval { LoadFile('config/database.yml') };

    if ($@) {
        return $c->render(
            json => {error => 'Could not load database configuration'},
            status => 500
        );
    }

    my $db_config = $config->{database};

    # Establish database connection
    my $dbh = eval {
        DBI->connect(
            $db_config->{dsn},
            $db_config->{username},
            $db_config->{password},
            { RaiseError => 1, AutoCommit => 0 }
        );
    };

    if ($@) {
        return $c->render(
            json => {error => 'Database connection failed: ' . $@},
            status => 500
        );
    }

    # Verify user's membership in the group
    my $membership_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM group_members gm
             JOIN user u ON gm.user_id = u.user_id
             WHERE gm.group_id = ? AND u.username = ?'
        );
        $prep->execute($group_id, $username);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Membership check failed: ' . $@},
            status => 500
        );
    }

    unless ($membership_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'User is not a member of this group'},
            status => 403
        );
    }

    # Fetch group members
    my $members_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT
                u.user_id,
                u.username,
                u.email,
                u.full_name,
                u.faculty,
                u.role,
                gm.date_joined,
                CASE WHEN ug.user_id = u.user_id THEN 1 ELSE 0 END as is_owner
            FROM group_members gm
            JOIN user u ON gm.user_id = u.user_id
            JOIN user_group ug ON gm.group_id = ug.group_id
            WHERE gm.group_id = ?'
        );
        $prep->execute($group_id);
        $prep;
    };


    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching group members failed: ' . $@},
            status => 500
        );
    }

    my $members = $members_sth->fetchall_arrayref({});
    $members_sth->finish;

    $dbh->disconnect;

    # Return members
    $c->render(json => $members);
}

sub addGroupMembers {
    my $c = shift;

    # Get the username from the session
    my $username = $c->session('login_name');
    my $group_id = $c->stash('group_id');

    # Get request data
    my $data = $c->req->json;
    my $user_ids = $data->{user_ids};

    unless ($username) {
        return $c->render(
            json => {error => 'User not authenticated'},
            status => 401
        );
    }

    # Validate input
    unless ($group_id && $user_ids && ref($user_ids) eq 'ARRAY' && scalar @$user_ids > 0) {
        return $c->render(
            json => {error => 'Group ID and at least one user ID are required'},
            status => 400
        );
    }

    # Load database configuration
    my $config = eval { LoadFile('config/database.yml') };

    if ($@) {
        return $c->render(
            json => {error => 'Could not load database configuration'},
            status => 500
        );
    }

    my $db_config = $config->{database};

    # Establish database connection
    my $dbh = eval {
        DBI->connect(
            $db_config->{dsn},
            $db_config->{username},
            $db_config->{password},
            { RaiseError => 1, AutoCommit => 0 }
        );
    };

    if ($@) {
        return $c->render(
            json => {error => 'Database connection failed: ' . $@},
            status => 500
        );
    }

    # Get user_id for the current user
    my $user_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT user_id FROM user WHERE username = ?'
        );
        $prep->execute($username);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching user_id failed: ' . $@},
            status => 500
        );
    }

    my $user_row = $user_sth->fetchrow_hashref;
    $user_sth->finish;

    unless ($user_row && $user_row->{user_id}) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'User not found'},
            status => 404
        );
    }

    my $current_user_id = $user_row->{user_id};

    # Check if the user is the group owner
    my $owner_check_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM user_group WHERE group_id = ? AND user_id = ?'
        );
        $prep->execute($group_id, $current_user_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group ownership check failed: ' . $@},
            status => 500
        );
    }

    unless ($owner_check_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Only group creators can add members'},
            status => 403
        );
    }

    # Prepare to insert new group members
    my $insert_sth = eval {
        $dbh->prepare(
            'INSERT IGNORE INTO group_members (group_id, user_id)
             VALUES (?, ?)'
        );
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Prepare statement failed: ' . $@},
            status => 500
        );
    }

    # Track successfully added and already existing members
    my @added_users;
    my @existing_users;

    # Add users to the group
    eval {
        for my $user_id (@$user_ids) {
            # Check if user is already in the group
            my $check_sth = $dbh->prepare(
                'SELECT 1 FROM group_members WHERE group_id = ? AND user_id = ?'
            );
            $check_sth->execute($group_id, $user_id);

            if ($check_sth->fetchrow_array) {
                push @existing_users, $user_id;
                next;
            }

            # Insert user into the group
            $insert_sth->execute($group_id, $user_id);
            push @added_users, $user_id;
        }

        $dbh->commit;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Adding members failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Members added successfully',
            added_users => \@added_users,
            existing_users => \@existing_users
        },
        status => 200
    );
}

sub removeGroupMember {
    my $c = shift;

    # Get the username from the session
    my $username = $c->session('login_name');
    my $group_id = $c->stash('group_id');

    # Get request data
    my $data = $c->req->json;
    my $user_id_to_remove = $data->{user_id};

    unless ($username) {
        return $c->render(
            json => {error => 'User not authenticated'},
            status => 401
        );
    }

    # Validate input
    unless ($group_id && $user_id_to_remove) {
        return $c->render(
            json => {error => 'Group ID and User ID are required'},
            status => 400
        );
    }

    # Load database configuration
    my $config = eval { LoadFile('config/database.yml') };

    if ($@) {
        return $c->render(
            json => {error => 'Could not load database configuration'},
            status => 500
        );
    }

    my $db_config = $config->{database};

    # Establish database connection
    my $dbh = eval {
        DBI->connect(
            $db_config->{dsn},
            $db_config->{username},
            $db_config->{password},
            { RaiseError => 1, AutoCommit => 0 }
        );
    };

    if ($@) {
        return $c->render(
            json => {error => 'Database connection failed: ' . $@},
            status => 500
        );
    }

    # Get user_id for the current user
    my $user_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT user_id FROM user WHERE username = ?'
        );
        $prep->execute($username);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching user_id failed: ' . $@},
            status => 500
        );
    }

    my $user_row = $user_sth->fetchrow_hashref;
    $user_sth->finish;

    unless ($user_row && $user_row->{user_id}) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'User not found'},
            status => 404
        );
    }

    my $current_user_id = $user_row->{user_id};

    # Check if the current user is the group owner
    my $owner_check_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM user_group WHERE group_id = ? AND user_id = ?'
        );
        $prep->execute($group_id, $current_user_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group ownership check failed: ' . $@},
            status => 500
        );
    }

    unless ($owner_check_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Only group owners can remove members'},
            status => 403
        );
    }

    # Prevent removing the group owner
    my $owner_removal_check_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM user_group WHERE group_id = ? AND user_id = ?'
        );
        $prep->execute($group_id, $user_id_to_remove);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Owner check failed: ' . $@},
            status => 500
        );
    }

    if ($owner_removal_check_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Cannot remove the group owner'},
            status => 403
        );
    }

    # Remove the member from the group
    my $remove_member_sth = eval {
        my $prep = $dbh->prepare(
            'DELETE FROM group_members WHERE group_id = ? AND user_id = ?'
        );
        $prep->execute($group_id, $user_id_to_remove);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Member removal failed: ' . $@},
            status => 500
        );
    }

    # Check if any rows were deleted
    if ($remove_member_sth->rows == 0) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'User was not a member of this group'},
            status => 404
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Member successfully removed from the group',
            user_id => $user_id_to_remove,
            group_id => $group_id
        },
        status => 200
    );
}

1;
