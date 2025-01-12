package backend::Controller::Login;

use Mojo::UserAgent;
use Data::Dumper;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';
use backend::Controller::User;
use Mojo::Util 'md5_sum';

sub login {
    my $c = shift;

    # Retrieve JSON data from the request body
    my $data = $c->req->json;

    my $username = $data->{username};
    my $password = $data->{password};

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

    # Check for admin authentication first
    my $admin_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT * FROM user WHERE username = ? AND password = ? AND role = "admin"'
        );
        $prep->execute($username, $password);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Admin authentication query failed: ' . $@},
            status => 500
        );
    }

    my $admin_rows = $admin_sth->fetchall_arrayref({});
    $admin_sth->finish;

    # If admin user exists and password matches
    if (@$admin_rows) {
        # Generate a unique session ID if not already set
        my $session_id = $c->session('session_id') || md5_sum(time . rand());
        # Create a session for admin
        $c->session(
            session_id  => $session_id,
            full_name   => $admin_rows->[0]->{full_name},
            login_name    => $admin_rows->[0]->{username},
            email       => $admin_rows->[0]->{email},
            role        => $admin_rows->[0]->{role},
            logged_in   => 1,
            expiration  => time + (8 * 60 * 60)  # 8 hours
        );

        $dbh->disconnect;

        return $c->render(json => {
            success     => \1,
            session_id  => $session_id,  # Return the session ID
            full_name   => $admin_rows->[0]->{full_name},
            description => $admin_rows->[0]->{role},
            login_name  => $admin_rows->[0]->{username},
            email       => $admin_rows->[0]->{email},
        });
    }

    # If not an admin, proceed with existing API authentication
    # Call the third-party API
    my $ua      = Mojo::UserAgent->new;
    my $url     = "http://web.fc.utm.my/ttms/web_man_webservice_json.cgi?entity=authentication&login=$username&password=$password";
    my $res     = $ua->get($url)->result;

    if ($res->is_success) {
        my $json = $res->json;
        if ($json && @$json) {
            my $sth = eval {
                my $prep = $dbh->prepare(
                    'SELECT * FROM user WHERE username=?'
                );
                $prep->execute(
                    $json->[0]->{login_name}
                );
                $prep;
            };

            if ($@) {
                $dbh->rollback;
                $dbh->disconnect;
                return $c->render(
                    json => {error => 'Fetching failed: ' . $@},
                    status => 500
                );
            }

            my $rows = $sth->fetchall_arrayref({});

            if (@$rows == 0) {
                $dbh->disconnect;
                return backend::Controller::User::register($c, $json->[0], $password);
            }

            $sth->finish;
            $dbh->disconnect;

            # Create a session
            $c->session(
                full_name   => $json->[0]->{full_name},
                description => $json->[0]->{description},
                login_name  => $json->[0]->{login_name},
                email       => $json->[0]->{email},
                logged_in   => 1,
                expiration  => time + (8 * 60 * 60)  # 8 hours
            );

            # Log session contents before rendering
            $c->app->log->info("Session created: " . Dumper($c->session));

            return $c->render(json => {
                success      => \1,
                session_id   => $json->[0]->{session_id},
                full_name    => $json->[0]->{full_name},
                description  => $json->[0]->{description},
                login_name   => $json->[0]->{login_name},
                email        => $json->[0]->{email}
            });
        } else {
            $dbh->disconnect;
            return $c->render(
                json   => { success => \0, message => 'Invalid username or password' },
                status => 401
            );
        }
    } else {
        $dbh->disconnect;
        return $c->render(
            json   => { success => \0, message => 'Failed to contact authentication service' },
            status => 500
        );
    }
};

sub logout {
    my $c = shift;

    # Log session contents before destroying
    $c->app->log->info("Session before logout: " . Dumper($c->session));

    # Destroy the session
    $c->session(expires => 1);

    # Log session contents after destroying
    $c->app->log->info("Session after logout: " . Dumper($c->session));

    $c->render(json => {
        success => \1,
        message => 'Logged out successfully'
    });
}

1;

