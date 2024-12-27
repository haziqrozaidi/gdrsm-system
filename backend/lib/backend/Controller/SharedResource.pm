package backend::Controller::SharedResource;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';

sub getAllSharedResources {
  my $c = shift;

  # Get the username from the session
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
      json => {error => 'Database connection failed: ' . $@},
      status => 500
    );
  }

  # Prepare and execute query to get shared resources
  my $sth = eval {
    my $prep = $dbh->prepare(
      'SELECT
        r.resource_id,
        r.name,
        r.description,
        u.email as owner,
        r.link,
        ur.date_shared,
        r.session,
        r.semester
      FROM
        resource r
      JOIN
        user_resource ur ON r.resource_id = ur.resource_id
      JOIN
        user u ON r.user_id = u.user_id
      WHERE
        ur.user_id = (SELECT user_id FROM user WHERE username = ?)'
    );
    $prep->execute($username);
    $prep;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Fetching shared resources failed: ' . $@},
      status => 500
    );
  }

  my $rows = $sth->fetchall_arrayref({});
  $sth->finish;
  $dbh->disconnect;

  # Return shared resources
  $c->render(json => $rows);
}

1;
