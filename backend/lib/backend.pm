package backend;
use Mojo::Base 'Mojolicious', -signatures;
use Data::Dumper;

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  # Configure session management
  $self->sessions->cookie_name('gdrsms_session');
  $self->sessions->default_expiration(28800);  # 8 hours
  $self->sessions->secure(1);
  $self->sessions->samesite('None');

  # Configure the application
  $self->secrets($config->{secrets});

  # Enable CORS globally
  $self->hook(before_dispatch => sub {
    my $c = shift;
    $c->res->headers->header('Access-Control-Allow-Origin' => 'http://localhost:5173');
    $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, OPTIONS');
    $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
    $c->res->headers->header('Access-Control-Allow-Credentials' => 'true');
  });

  # Router
  my $r = $self->routes;

  # Handle preflight requests
  $r->options('*')->to(cb => sub ($c) {
    $c->res->headers->header('Access-Control-Allow-Origin' => 'http://localhost:5173');
    $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, OPTIONS');
    $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
    $c->res->headers->header('Access-Control-Allow-Credentials' => 'true');
    $c->res->headers->header('Access-Control-Max-Age' => '86400');
    $c->render(text => '', status => 204);
  });

  # Normal routes to controller
  $r->get('/')->to('Example#welcome');
  $r->post('/api/users/register')->to('User#register');
  $r->post('/api/users/login')->to('Login#login');
  $r->post('/api/users/logout')->to('Login#logout');

  # Protected routes
  my $authorized = $r->under(sub ($c) {
    # Detailed logging for debugging
    $c->app->log->debug("Session contents: " . Dumper($c->session));
    $c->app->log->debug("Logged in status: " . ($c->session('logged_in') // 'Not set'));

    # Check if user is logged in
    if ($c->session('logged_in')) {
      return 1;
    }

    # Unauthorized access
    $c->render(
      json => {
        success => \0,
        message => 'Unauthorized access. Please log in.'
      },
      status => 401
    );
    return 0;
  });

  $authorized->get('/api/resources')->to('Resource#getAllResources');
  $authorized->post('/api/resources')->to('Resource#addResource');
}

1;
