package backend::Controller::Resource;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';

sub getAllResources {
  my $c = shift;

  my $user = $c->req->json;

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
      'SELECT * FROM resource'
    );
    $prep->execute;
    $dbh->commit;
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
  $sth->finish;

  $dbh->disconnect;

  # Return success response
  $c->render(json => $rows);
}

1;
