package backend::Controller::Login;

use Mojo::UserAgent;
use Data::Dumper;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';
use backend::Controller::User;

sub login {
    my $c = shift;

    # Retrieve JSON data from the request body
    my $data = $c->req->json;
    
    my $username = $data->{username};
    my $password = $data->{password};
    
    # Call the third-party API
    my $ua      = Mojo::UserAgent->new;
    my $url     = "http://web.fc.utm.my/ttms/web_man_webservice_json.cgi?entity=authentication&login=$username&password=$password";
    my $res     = $ua->get($url)->result;

    if ($res->is_success) {
        my $json = $res->json;
        if ($json && @$json) {
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

            $c->render(json => {
                success      => \1,
                session_id   => $json->[0]->{session_id},
                full_name    => $json->[0]->{full_name},
                description  => $json->[0]->{description},
                login_name   => $json->[0]->{login_name},
                email        => $json->[0]->{email}
            });
        } else {
            $c->render(
                json   => { success => \0, message => 'Invalid username or password' },
                status => 401
            );
        }
    } else {
        $c->render(
            json   => { success => \0, message => 'Failed to contact authentication service' },
            status => 500
        );
    }
};

1;

