package backend::Controller::UserGroup;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';

sub getAllUserGroups {
    my $c = shift;

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

    my $user_id = $user_row->{user_id};

    # Fetch groups for the current user
    my $groups_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT
                ug.group_id,
                ug.name,
                ug.description,
                ug.date_created,
                ug.user_id AS owner_id,
                (SELECT COUNT(*) FROM group_members gm WHERE gm.group_id = ug.group_id) as member_count,
                CASE WHEN ug.user_id = ? THEN "Created" ELSE "Invited" END as membership_status
            FROM user_group ug
            JOIN group_members gm ON ug.group_id = gm.group_id
            WHERE gm.user_id = ?'
        );
        $prep->execute($user_id, $user_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching groups failed: ' . $@},
            status => 500
        );
    }

    my $groups = $groups_sth->fetchall_arrayref({});
    $groups_sth->finish;

    $dbh->disconnect;

    # Return groups
    $c->render(json => $groups);
}

sub createGroup {
    my $c = shift;

    # Get the username from the session
    my $username = $c->session('login_name');

    unless ($username) {
        return $c->render(
            json => {error => 'User not authenticated'},
            status => 401
        );
    }

    # Get JSON body
    my $group_data = $c->req->json;

    # Validate input
    unless ($group_data->{name}) {
        return $c->render(
            json => {error => 'Group name is required'},
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

    my $user_id = $user_row->{user_id};

    # Insert new group
    my $group_sth = eval {
        my $prep = $dbh->prepare(
            'INSERT INTO user_group (name, description, user_id) VALUES (?, ?, ?)'
        );
        $prep->execute(
            $group_data->{name},
            $group_data->{description} // '',
            $user_id
        );
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group creation failed: ' . $@},
            status => 500
        );
    }

    # Get the ID of the newly created group
    my $group_id = $dbh->last_insert_id(undef, undef, undef, undef);

    # Add the group creator as the first member
    my $member_sth = eval {
        my $prep = $dbh->prepare(
            'INSERT INTO group_members (user_id, group_id) VALUES (?, ?)'
        );
        $prep->execute($user_id, $group_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Adding group member failed: ' . $@},
            status => 500
        );
    }

    # Commit the transaction
    eval { $dbh->commit; };
    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Transaction commit failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return the newly created group details
    $c->render(
        json => {
            group_id => $group_id,
            name => $group_data->{name},
            description => $group_data->{description} // ''
        },
        status => 201
    );
}

sub leaveGroup {
    my $c = shift;

    # Get the username from the session
    my $username = $c->session('login_name');
    my $group_id = $c->stash('group_id');

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

    my $user_id = $user_row->{user_id};

    # Check if the user is the group owner
    my $owner_check_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM user_group WHERE group_id = ? AND user_id = ?'
        );
        $prep->execute($group_id, $user_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group ownership check failed: ' . $@},
            status => 500
        );
    }

    # Prevent group owner from leaving their own group
    if ($owner_check_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group owner cannot leave their own group'},
            status => 403
        );
    }

    # Remove user from group members
    my $leave_group_sth = eval {
        my $prep = $dbh->prepare(
            'DELETE FROM group_members WHERE group_id = ? AND user_id = ?'
        );
        $prep->execute($group_id, $user_id);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Leaving group failed: ' . $@},
            status => 500
        );
    }

    # Check if any rows were deleted
    if ($leave_group_sth->rows == 0) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'You are not a member of this group'},
            status => 404
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Successfully left the group',
            group_id => $group_id
        },
        status => 200
    );
}

sub deleteGroup {
    my $c = shift;

    # Get the username from the session
    my $username = $c->session('login_name');
    my $group_id = $c->stash('group_id');

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

    my $user_id = $user_row->{user_id};

    # Check if the user is the group owner
    my $owner_check_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM user_group WHERE group_id = ? AND user_id = ?'
        );
        $prep->execute($group_id, $user_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group ownership check failed: ' . $@},
            status => 500
        );
    }

    # Ensure only the group owner can delete the group
    unless ($owner_check_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Only the group owner can delete the group'},
            status => 403
        );
    }

    # Delete group resources first (to handle foreign key constraints)
    my $delete_resources_sth = eval {
        my $prep = $dbh->prepare(
            'DELETE gr FROM group_resource gr
             JOIN resource r ON gr.resource_id = r.resource_id
             WHERE gr.group_id = ?'
        );
        $prep->execute($group_id);
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Deleting group resources failed: ' . $@},
            status => 500
        );
    }

    # Delete group members
    my $delete_members_sth = eval {
        my $prep = $dbh->prepare(
            'DELETE FROM group_members WHERE group_id = ?'
        );
        $prep->execute($group_id);
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Deleting group members failed: ' . $@},
            status => 500
        );
    }

    # Delete the group itself
    my $delete_group_sth = eval {
        my $prep = $dbh->prepare(
            'DELETE FROM user_group WHERE group_id = ?'
        );
        $prep->execute($group_id);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group deletion failed: ' . $@},
            status => 500
        );
    }

    # Check if the group was actually deleted
    if ($delete_group_sth->rows == 0) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group not found'},
            status => 404
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Group successfully deleted',
            group_id => $group_id
        },
        status => 200
    );
}

1;
