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


1;
