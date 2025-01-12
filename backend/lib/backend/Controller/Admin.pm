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

1;
