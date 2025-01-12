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

1;
