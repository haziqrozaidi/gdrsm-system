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

sub addResource {
  my $c = shift;

  my $resource = $c->req->json;

  # Input validation
  unless ($resource->{name} && $resource->{type} && $resource->{description} && $resource->{owner} && $resource->{link} && $resource->{session} && $resource->{semester} && $resource->{folder} && $resource->{category}) {
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
      'INSERT INTO resource (link, name, type, description, owner, session, semester, user_id, folder_id, category_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1, 1)'
    );
    $prep->execute(
      $resource->{link},
      $resource->{name},
      $resource->{type},
      $resource->{description},
      $resource->{owner},
      $resource->{session},
      $resource->{semester}
    );
    $dbh->commit;
    $prep;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Saving failed: ' . $@},
      status => 500
    );
  }

  $dbh->disconnect;

  # Return success response
  $c->render(
    json => {
      message => 'Resource saved successfully',
    },
    status => 201
  );
}

1;
