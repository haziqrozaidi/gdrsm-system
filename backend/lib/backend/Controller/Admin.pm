package backend::Controller::Admin;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';

sub getAllResources {
    my $c = shift;

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

    # Fetch all resources without filtering by user
    my $sth = eval {
        my $prep = $dbh->prepare(
            'SELECT r.*,
              f.name AS folder_name,
              c.name AS category_name
            FROM resource r
            LEFT JOIN folder f ON r.folder_id = f.folder_id
            LEFT JOIN category c ON r.category_id = c.category_id'
        );
        $prep->execute();
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching resources failed: ' . $@},
            status => 500
        );
    }

    my $rows = $sth->fetchall_arrayref({});
    $sth->finish;
    $dbh->disconnect;

    $c->render(json => $rows);
}

sub getAllFolders {
    my $c = shift;

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
            json => {error => 'Database connection failed: ' .$@},
            status => 500
        );
    }

    # Fetch all folders with additional information
    my $sth = eval {
        my $prep = $dbh->prepare(
            'SELECT f.*, u.email AS owner_email 
             FROM folder f
             JOIN user u ON f.user_id = u.user_id
             ORDER BY f.date_created DESC'
        );
        $prep->execute();
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching folders failed: ' . $@},
            status => 500
        );
    }

    my $folders = $sth->fetchall_arrayref({});
    $sth->finish;

    $dbh->disconnect;

    $c->render(json => $folders)
}

sub getAllGroups {
    my $c = shift;

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

    # Fetch all groups with additional information
    my $groups_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 
                ug.group_id,
                ug.name,
                ug.description,
                ug.date_created,
                ug.user_id AS owner_id,
                u.email AS owner_email,
                (SELECT COUNT(*) FROM group_members gm WHERE gm.group_id = ug.group_id) as member_count,
                CASE 
                    WHEN ug.user_id IS NOT NULL THEN "Created" 
                    ELSE "Invited" 
                END as membership_status
            FROM user_group ug
            LEFT JOIN user u ON ug.user_id = u.user_id
            ORDER BY ug.date_created DESC'
        );
        $prep->execute();
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

    # Return all groups
    $c->render(json => $groups);
}

sub getSharedUsers {
    my $c = shift;
    my $resource_id = $c->param('resource_id');

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

    # Verify resource exists
    my $resource_exists = $dbh->selectrow_array(
        'SELECT 1 FROM resource WHERE resource_id = ?',
        undef,
        $resource_id
    );

    unless ($resource_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not found'},
            status => 404
        );
    }

    # Query to fetch shared users with additional details
    my $sth = $dbh->prepare(
        'SELECT 
            u.user_id, 
            u.email, 
            u.full_name,
            r.name AS resource_name,
            r.owner AS resource_owner,
            ur.date_shared
        FROM user u
        JOIN user_resource ur ON u.user_id = ur.user_id
        JOIN resource r ON ur.resource_id = r.resource_id
        WHERE ur.resource_id = ?'
    );
    $sth->execute($resource_id);

    my $shared_users = $sth->fetchall_arrayref({});
    $sth->finish;
    $dbh->disconnect;

    $c->render(json => $shared_users);
}

sub getSharedGroups {
    my $c = shift;
    my $resource_id = $c->param('resource_id');

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

    # Verify resource exists
    my $resource_exists = $dbh->selectrow_array(
        'SELECT 1 FROM resource WHERE resource_id = ?',
        undef,
        $resource_id
    );

    unless ($resource_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not found'},
            status => 404
        );
    }

    # Query to fetch shared groups with additional details
    my $sth = $dbh->prepare(
        'SELECT 
            ug.group_id, 
            ug.name, 
            ug.description,
            r.name AS resource_name,
            r.owner AS resource_owner,
            gr.date_shared,
            (SELECT COUNT(*) FROM group_members gm WHERE gm.group_id = ug.group_id) AS member_count,
            u.email AS group_owner_email
        FROM user_group ug
        JOIN group_resource gr ON ug.group_id = gr.group_id
        JOIN resource r ON gr.resource_id = r.resource_id
        JOIN user u ON ug.user_id = u.user_id
        WHERE gr.resource_id = ?'
    );
    $sth->execute($resource_id);

    my $shared_groups = $sth->fetchall_arrayref({});
    $sth->finish;
    $dbh->disconnect;

    $c->render(json => $shared_groups);
}

sub addResource {
    my $c = shift;

    my $username = $c->session('login_name');
    my $description = $c->session('description');
    my $resource = $c->req->json;
    my $email = $c->session('email');

    # Input validation with additional checks for admin
    unless ($resource->{name} && $resource->{type} && $resource->{description} 
            && $resource->{link} && $resource->{session} && $resource->{semester} 
            && $resource->{folder} && $resource->{category} && $resource->{owner}) {
        return $c->render(
            json => {error => 'Missing required fields'},
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

    # Verify owner user exists
    my $owner_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT user_id FROM user WHERE email = ?'
        );
        $prep->execute($resource->{owner});
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching owner user_id failed: ' . $@},
            status => 500
        );
    }

    my $owner_row = $owner_sth->fetchrow_hashref;
    $owner_sth->finish;

    unless ($owner_row && $owner_row->{user_id}) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Owner user not found'},
            status => 404
        );
    }

    my $owner_id = $owner_row->{user_id};

    # Verify folder exists
    my $folder_exists = $dbh->selectrow_array(
        'SELECT 1 FROM folder WHERE folder_id = ?',
        undef,
        $resource->{folder}
    );

    unless ($folder_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Specified folder does not exist'},
            status => 400
        );
    }

    # Verify category exists
    my $category_exists = $dbh->selectrow_array(
        'SELECT 1 FROM category WHERE category_id = ?',
        undef,
        $resource->{category}
    );

    unless ($category_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Specified category does not exist'},
            status => 400
        );
    }

    # Prepare and execute insert
    my $sth = eval {
        my $prep = $dbh->prepare(
            'INSERT INTO resource (
                link, 
                name, 
                type, 
                description, 
                owner, 
                session, 
                semester, 
                user_id, 
                folder_id, 
                category_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $prep->execute(
            $resource->{link},
            $resource->{name},
            $resource->{type},
            $resource->{description},
            $resource->{owner},
            $resource->{session},
            $resource->{semester},
            $owner_id,
            $resource->{folder},
            $resource->{category}
        );
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Saving failed: ' . $@},
            status => 500
        );
    }

    # Get the ID of the newly inserted resource
    my $new_resource_id = $dbh->last_insert_id(undef, undef, 'resource', 'resource_id');

    $dbh->disconnect;

    # Return success response with new resource details
    $c->render(
        json => {
            message => 'Resource saved successfully',
            resource_id => $new_resource_id,
            created_by => $username
        },
        status => 201
    );
}

sub updateResource {
    my $c = shift;

    my $username = $c->session('login_name');
    my $description = $c->session('description');
    my $resource = $c->req->json;
    my $resource_id = $c->stash('id');  # Get resource ID from URL

    # Input validation
    unless ($resource->{name} && $resource->{type} && $resource->{description} 
            && $resource->{link} && $resource->{session} && $resource->{semester} 
            && $resource->{folder} && $resource->{category}) {
        return $c->render(
            json => {error => 'Missing required fields'},
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

    # Verify resource exists
    my $resource_exists = $dbh->selectrow_hashref(
        'SELECT owner FROM resource WHERE resource_id = ?',
        undef,
        $resource_id
    );

    unless ($resource_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not found'},
            status => 404
        );
    }

    # Verify folder exists
    my $folder_exists = $dbh->selectrow_array(
        'SELECT 1 FROM folder WHERE folder_id = ?',
        undef,
        $resource->{folder}
    );

    unless ($folder_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Specified folder does not exist'},
            status => 400
        );
    }

    # Verify category exists
    my $category_exists = $dbh->selectrow_array(
        'SELECT 1 FROM category WHERE category_id = ?',
        undef,
        $resource->{category}
    );

    unless ($category_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Specified category does not exist'},
            status => 400
        );
    }

    # Prepare and execute update
    my $sth = eval {
        my $prep = $dbh->prepare(
            'UPDATE resource
             SET link = ?, 
                 name = ?, 
                 type = ?, 
                 description = ?,
                 session = ?, 
                 semester = ?, 
                 folder_id = ?, 
                 category_id = ?
             WHERE resource_id = ?'
        );
        $prep->execute(
            $resource->{link},
            $resource->{name},
            $resource->{type},
            $resource->{description},
            $resource->{session},
            $resource->{semester},
            $resource->{folder},
            $resource->{category},
            $resource_id
        );
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Update failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Check if any rows were updated
    if ($sth->rows == 0) {
        return $c->render(
            json => {error => 'Resource update failed'},
            status => 500
        );
    }

    # Return success response
    $c->render(
        json => {
            message => 'Resource updated successfully',
            resource_id => $resource_id
        },
        status => 200
    );
}

sub deleteResource {
    my $c = shift;

    my $username = $c->session('login_name');
    my $description = $c->session('description');
    my $resource_id = $c->stash('id');  # Get resource ID from URL

    unless ($resource_id) {
        return $c->render(
            json => {error => 'Missing resource ID'},
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

    # First, check if the resource exists
    my $resource_exists = $dbh->selectrow_hashref(
        'SELECT resource_id, name, owner FROM resource WHERE resource_id = ?',
        undef,
        $resource_id
    );

    unless ($resource_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not found'},
            status => 404
        );
    }

    # Prepare and execute delete
    my $sth = eval {
        my $prep = $dbh->prepare(
            'DELETE FROM resource WHERE resource_id = ?'
        );
        $prep->execute($resource_id);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Delete failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Check if any rows were deleted
    if ($sth->rows == 0) {
        return $c->render(
            json => {error => 'Resource deletion failed'},
            status => 500
        );
    }

    # Return success response
    $c->render(
        json => {
            message => 'Resource deleted successfully',
            resource_id => $resource_id,
            resource_name => $resource_exists->{name},
            original_owner => $resource_exists->{owner},
            deleted_by => $username
        },
        status => 200
    );
}

sub unshareResource {
    my $c = shift;
    my $resource_data = $c->req->json;

    # Check if the user is an admin
    my $username = $c->session('login_name');
    my $description = $c->session('description');

    # Validate input
    unless ($resource_data->{resource_id} && $resource_data->{user_id}) {
        return $c->render(
            json => {error => 'Missing resource ID or user ID'},
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

    # Verify resource exists
    my $resource_exists = $dbh->selectrow_hashref(
        'SELECT resource_id, name, owner FROM resource WHERE resource_id = ?',
        undef,
        $resource_data->{resource_id}
    );

    unless ($resource_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not found'},
            status => 404
        );
    }

    # Verify user exists
    my $user_exists = $dbh->selectrow_hashref(
        'SELECT user_id, username FROM user WHERE user_id = ?',
        undef,
        $resource_data->{user_id}
    );

    unless ($user_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'User not found'},
            status => 404
        );
    }

    # Prepare and execute unshare
    my $sth = $dbh->prepare(
        'DELETE FROM user_resource
          WHERE resource_id = ? AND user_id = ?'
    );
    $sth->execute($resource_data->{resource_id}, $resource_data->{user_id});
    $dbh->commit;

    $dbh->disconnect;

    # Check if any rows were deleted
    if ($sth->rows == 0) {
        return $c->render(
            json => {error => 'Resource not shared with specified user'},
            status => 404
        );
    }

    # Return success response
    $c->render(
        json => {
            message => 'Resource unshared successfully',
            resource_id => $resource_data->{resource_id},
            resource_name => $resource_exists->{name},
            user_id => $resource_data->{user_id},
            username => $user_exists->{username},
            unshared_by => $username
        },
        status => 200
    );
}

sub unshareResourceFromGroup {
    my $c = shift;

    # Check if the user is an admin
    my $username = $c->session('login_name');
    my $description = $c->session('description');

    # Get request data
    my $data = $c->req->json;
    my $resource_id = $data->{resource_id};
    my $group_id = $data->{group_id};

    # Validate input
    unless ($resource_id && $group_id) {
        return $c->render(
            json => {error => 'Resource ID and Group ID are required'},
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

    # Verify resource exists
    my $resource_exists = $dbh->selectrow_hashref(
        'SELECT resource_id, name, owner FROM resource WHERE resource_id = ?',
        undef,
        $resource_id
    );

    unless ($resource_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not found'},
            status => 404
        );
    }

    # Verify group exists
    my $group_exists = $dbh->selectrow_hashref(
        'SELECT group_id, name FROM user_group WHERE group_id = ?',
        undef,
        $group_id
    );

    unless ($group_exists) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group not found'},
            status => 404
        );
    }

    # Check if resource is shared with the group
    my $is_shared = $dbh->selectrow_array(
        'SELECT 1 FROM group_resource WHERE resource_id = ? AND group_id = ?',
        undef,
        $resource_id,
        $group_id
    );

    unless ($is_shared) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not shared with the group'},
            status => 404
        );
    }

    # Remove resource from group
    my $unshare_sth = eval {
        my $prep = $dbh->prepare(
            'DELETE FROM group_resource 
             WHERE resource_id = ? AND group_id = ?'
        );
        $prep->execute($resource_id, $group_id);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Unsharing failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Resource unshared from group successfully',
            resource_id => $resource_id,
            resource_name => $resource_exists->{name},
            group_id => $group_id,
            group_name => $group_exists->{name},
            unshared_by => $username
        },
        status => 200
    );
}

sub shareResourceWithGroupAndUsers {
    my $c = shift;

    # Check if the user is an admin
    my $username = $c->session('login_name');
    my $description = $c->session('description');

    # Get request data
    my $data = $c->req->json;
    my $resource_id = $data->{resource_id};
    my $group_ids = $data->{group_ids} || [];
    my $user_ids = $data->{user_ids} || [];
    my $owner = $data->{owner};  # Optional: specify resource owner

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

    # Verify resource exists
    my $resource = $dbh->selectrow_hashref(
        'SELECT resource_id, name, user_id, owner FROM resource WHERE resource_id = ?',
        undef,
        $resource_id
    );

    unless ($resource) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Resource not found'},
            status => 404
        );
    }

    # Determine the owner's user_id
    my $owner_user_id;
    my $owner_username;

    if ($owner) {
        # If owner is specified, validate and get their user_id
        my $owner_details = $dbh->selectrow_hashref(
            'SELECT user_id, username FROM user WHERE username = ?',
            undef,
            $owner
        );

        unless ($owner_details) {
            $dbh->disconnect;
            return $c->render(
                json => {error => 'Specified owner not found'},
                status => 404
            );
        }

        $owner_user_id = $owner_details->{user_id};
        $owner_username = $owner_details->{username};
    } else {
        # If no owner specified, use the current resource's owner
        $owner_user_id = $resource->{user_id};
        $owner_username = $resource->{owner};
    }

    # Prepare statements for sharing
    my $group_share_sth = $dbh->prepare(
        'INSERT IGNORE INTO group_resource (group_id, resource_id) VALUES (?, ?)'
    );

    my $user_share_sth = $dbh->prepare(
        'INSERT IGNORE INTO user_resource (user_id, resource_id) VALUES (?, ?)'
    );

    # Track sharing results
    my @shared_groups;
    my @shared_users;
    my @invalid_groups;
    my @invalid_users;

    # Validate groups
    my %valid_groups;
    if (@$group_ids) {
        my $groups_validation = $dbh->selectall_arrayref(
            'SELECT group_id FROM user_group WHERE group_id IN (' . 
            join(',', map { $dbh->quote($_) } @$group_ids) . ')'
        );
        %valid_groups = map { $_->[0] => 1 } @$groups_validation;
    }

    # Validate users
    my %valid_users;
    if (@$user_ids) {
        my $users_validation = $dbh->selectall_arrayref(
            'SELECT user_id FROM user WHERE user_id IN (' . 
            join(',', map { $dbh->quote($_) } @$user_ids) . ')'
        );
        %valid_users = map { $_->[0] => 1 } @$users_validation;
    }

    # Share with groups
    foreach my $group_id (@$group_ids) {
        if ($valid_groups{$group_id}) {
            $group_share_sth->execute($group_id, $resource_id);
            push @shared_groups, $group_id;
        } else {
            push @invalid_groups, $group_id;
        }
    }

    # Share with individual users
    foreach my $user_id (@$user_ids) {
        if ($valid_users{$user_id}) {
            $user_share_sth->execute($user_id, $resource_id);
            push @shared_users, $user_id;
        } else {
            push @invalid_users, $user_id;
        }
    }

    eval { $dbh->commit; };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Sharing failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return comprehensive response
    $c->render(
        json => {
            message => 'Resource shared successfully',
            resource_id => $resource_id,
            resource_name => $resource->{name},
            owner => $owner_username,
            shared_groups => \@shared_groups,
            shared_users => \@shared_users,
            invalid_groups => \@invalid_groups,
            invalid_users => \@invalid_users,
            shared_by => $username
        },
        status => 200
    );
}

sub updateGroup {
    my $c = shift;

    # Check if the user is an admin
    my $username = $c->session('login_name');
    my $description = $c->session('description');
    my $group_id = $c->stash('group_id');

    # Get request body
    my $group_data = $c->req->json;
    my $new_name = $group_data->{name};
    my $new_description = $group_data->{description};
    
    # Validate input
    unless ($new_name && length($new_name) > 0) {
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

    # Check if group exists
    my $group_check_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT user_id, name, description FROM user_group WHERE group_id = ?'
        );
        $prep->execute($group_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group check failed: ' . $@},
            status => 500
        );
    }

    my $group_details = $group_check_sth->fetchrow_hashref;

    # Validate group existence
    unless ($group_details) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group not found'},
            status => 404
        );
    }

    # Update group details
    my $update_group_sth = eval {
        my $prep = $dbh->prepare(
            'UPDATE user_group
             SET name = ?, description = ?
             WHERE group_id = ?'
        );
        $prep->execute($new_name, $new_description, $group_id);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Group update failed: ' . $@},
            status => 500
        );
    }

    # Check if the group was actually updated
    if ($update_group_sth->rows == 0) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'No changes were made'},
            status => 400
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Group successfully updated by admin',
            group_id => $group_id,
            name => $new_name,
            description => $new_description,
            previous_name => $group_details->{name},
            previous_description => $group_details->{description},
            updated_by => $username
        },
        status => 200
    );
}

1;
