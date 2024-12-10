package backend::Controller::User;

use Mojo::UserAgent;
use Data::Dumper;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';

sub login {
    my $c = shift;

    # Retrieve JSON data from the request body
    my $data = $c->req->json;
    #Debugging data received
    $c->app->log->debug("Received Data: " . Dumper($data));
    my $username = $data->{username};
    my $password = $data->{password};
    # Call the third-party API
    my $ua      = Mojo::UserAgent->new;
    my $url     = "http://web.fc.utm.my/ttms/web_man_webservice_json.cgi?entity=authentication&login=$username&password=$password";
    my $res     = $ua->get($url)->result;

    if ($res->is_success) {
        my $json = $res->json;
        if ($json && @$json) {
            $c->render(json => {
                success      => \1,
                session_id   => $json->[0]->{session_id},
                full_name    => $json->[0]->{full_name},
                description  => $json->[0]->{description}
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

