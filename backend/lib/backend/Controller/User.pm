package backend::Controller::User;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';

sub register {
  my $c = shift;

  my $user = $c->req->json;

  # Input validation
  unless ($user->{username} && $user->{full_name} && $user->{email} && $user->{password} && $user->{faculty}) {
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

  # Prepare and execute insert
  my $sth = eval {
    my $prep = $dbh->prepare(
      'INSERT INTO user (username, full_name, email, password, role, faculty)
      VALUES (?, ?, ?, ?, "student", ?)'
    );
    $prep->execute(
      $user->{username}, 
      $user->{full_name}, 
      $user->{email}, 
      $user->{password},
      $user->{faculty}
    );
    $dbh->commit;
    $prep;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Registration failed: ' . $@}, 
      status => 500
    );
  }

  $dbh->disconnect;

  # Return success response
  $c->render(
    json => {
      message => 'User registered successfully',
      username => $user->{username}
    },
    status => 201
  );
}

1;
