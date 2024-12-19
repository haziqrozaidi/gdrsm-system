package backend::Controller::Folder;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use YAML::XS 'LoadFile';

sub getAllFolders {
    my $c = shift;

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
            json => {error => 'Database connection failed: ' .$@},
            status => 500
        );
    }

    # Get the user ID
    my $user_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT user_id FROM user WHERE username = ?'
        );
        $prep->execute($username);
        $prep;
    };

    if ($@) {
        $dbh->rollback;
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

    # Get the folders by user ID
    my $user_id = $user_row->{user_id};

    my $sth = eval {
        my $prep = $dbh->prepare(
            'SELECT * FROM folder WHERE user_id = ?'
        );
        $prep->execute($user_id);
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

1;
