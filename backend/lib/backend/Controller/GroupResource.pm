package backend::Controller::GroupResource;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use YAML::XS 'LoadFile';

sub getGroupResources {
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

    # Fetch group resources
    my $resources_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT r.resource_id, r.name, r.type, r.description, r.link,
                    r.owner, r.session, r.semester, r.date_created,
                    f.name AS folder_name,
                    c.name AS category_name
             FROM group_resource gr
             JOIN resource r ON gr.resource_id = r.resource_id
             LEFT JOIN folder f ON r.folder_id = f.folder_id
             LEFT JOIN category c ON r.category_id = c.category_id
             WHERE gr.group_id = ?'
        );
        $prep->execute($group_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching group resources failed: ' . $@},
            status => 500
        );
    }

    my $resources = $resources_sth->fetchall_arrayref({});
    $resources_sth->finish;

    $dbh->disconnect;

    # Return resources
    $c->render(json => $resources);
}

sub shareResourceWithGroup {
    my $c = shift;

    # Get the username from the session
    my $username = $c->session('login_name');

    unless ($username) {
        return $c->render(
            json => {error => 'User not authenticated'},
            status => 401
        );
    }

    # Get request data
    my $data = $c->req->json;
    my $group_id = $data->{group_id};
    my @resource_ids = @{$data->{resource_ids}};

    # Validate input
    unless ($group_id && scalar(@resource_ids) > 0) {
        return $c->render(
            json => {error => 'Group ID and resources are required'},
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

    # Check if user is a member of the group or the group owner
    my $group_check_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM group_members gm
             WHERE gm.group_id = ? AND gm.user_id = ?'
        );
        $prep->execute($group_id, $user_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group membership check failed: ' . $@},
            status => 500
        );
    }

    unless ($group_check_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'You are not a member of this group'},
            status => 403
        );
    }

    # Verify resource ownership
    my $ownership_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM resource
             WHERE resource_id = ? AND user_id = ?'
        );
        $prep;
    };

    # Prepare insert statement for group resources
    my $insert_sth = eval {
        my $prep = $dbh->prepare(
            'INSERT IGNORE INTO group_resource (group_id, resource_id) VALUES (?, ?)'
        );
        $prep;
    };

    # Validate and insert resources
    eval {
        foreach my $resource_id (@resource_ids) {
            # Check resource ownership
            $ownership_sth->execute($resource_id, $user_id);

            unless ($ownership_sth->fetchrow_array) {
                die "Resource $resource_id is not owned by the user";
            }

            # Insert resource into group_resource
            $insert_sth->execute($group_id, $resource_id);
        }

        $dbh->commit;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource sharing failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Resources shared successfully',
            shared_resources_count => scalar(@resource_ids)
        },
        status => 200
    );
}

sub removeResourceFromGroup {
    my $c = shift;

    # Get the username from the session
    my $username = $c->session('login_name');
    my $group_id = $c->stash('group_id');

    # Get request data
    my $data = $c->req->json;
    my $resource_id = $data->{resource_id};

    unless ($username) {
        return $c->render(
            json => {error => 'User not authenticated'},
            status => 401
        );
    }

    # Validate input
    unless ($group_id && $resource_id) {
        return $c->render(
            json => {error => 'Group ID and Resource ID are required'},
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

    # Check if user is the group owner
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

    unless ($owner_check_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Only group owners can remove resources'},
            status => 403
        );
    }

    # Remove resource from group
    my $remove_resource_sth = eval {
        my $prep = $dbh->prepare(
            'DELETE FROM group_resource
             WHERE group_id = ? AND resource_id = ?'
        );
        $prep->execute($group_id, $resource_id);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource removal failed: ' . $@},
            status => 500
        );
    }

    # Check if any rows were deleted
    if ($remove_resource_sth->rows == 0) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not found in the group'},
            status => 404
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Resource successfully removed from the group',
            resource_id => $resource_id,
            group_id => $group_id
        },
        status => 200
    );
}

sub shareResourceWithGroupAndUsers {
    my $c = shift;

    # Get the username from the session
    my $username = $c->session('login_name');

    unless ($username) {
        return $c->render(
            json => {error => 'User not authenticated'},
            status => 401
        );
    }

    # Get request data
    my $data = $c->req->json;
    my $resource_id = $data->{resource_id};
    my $group_ids = $data->{group_ids} || [];
    my $user_ids = $data->{user_ids} || [];

    # Validate input
    unless ($resource_id) {
        return $c->render(
            json => {error => 'Resource ID is required'},
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

    # Verify resource ownership
    my $ownership_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM resource WHERE resource_id = ? AND user_id = ?'
        );
        $prep->execute($resource_id, $current_user_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource ownership check failed: ' . $@},
            status => 500
        );
    }

    unless ($ownership_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'You do not own this resource'},
            status => 403
        );
    }

    # Prepare statements for sharing
    my $group_share_sth = eval {
        $dbh->prepare(
            'INSERT IGNORE INTO group_resource (group_id, resource_id) VALUES (?, ?)'
        );
    };

    my $user_share_sth = eval {
        $dbh->prepare(
            'INSERT IGNORE INTO user_resource (user_id, resource_id) VALUES (?, ?)'
        );
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Prepare statement failed: ' . $@},
            status => 500
        );
    }

    # Track sharing results
    my @shared_groups;
    my @shared_users;

    # Share with groups
    eval {
        foreach my $group_id (@$group_ids) {
            $group_share_sth->execute($group_id, $resource_id);
            push @shared_groups, $group_id;
        }

        # Share with individual users
        foreach my $user_id (@$user_ids) {
            $user_share_sth->execute($user_id, $resource_id);
            push @shared_users, $user_id;
        }

        $dbh->commit;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Sharing failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Resource shared successfully',
            shared_groups => \@shared_groups,
            shared_users => \@shared_users
        },
        status => 200
    );
}

1;
