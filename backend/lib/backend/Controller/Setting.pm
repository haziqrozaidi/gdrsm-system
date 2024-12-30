package backend::Controller::Setting;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use Data::Dumper;

sub getUserProfile {
    my $c = shift;

    # Retrieve user information from the session
    my $username = $c->session('login_name');
    my $email = $c->session('email');
    my $full_name = $c->session('full_name');
    my $description = $c->session('description');

    # Return an unauthorized error if the user is not logged in
    unless ($username) {
        return $c->render(
            json => {
                success => \0,
                error  => 'User not authenticated'
            },
            status => 401
        );
    }

    # Construct user information directly from session data
    my $user_data = {
        username  => $username,
        full_name => $full_name,
        email     => $email,
        role      => $description || 'student',    # Use description as the role
        faculty   => 'Faculty of Computing'        # Default faculty
    };

    # Return the user profile
    return $c->render(
        json => {
            success => \1,
            user    => $user_data
        },
        status => 200
    );
}

1;
