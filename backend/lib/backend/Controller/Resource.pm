package backend::Controller::Resource;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';

sub getAllResources {
  my $c = shift;

  my $user = $c->req->json;

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

  my $user_id = $user_row->{user_id};

  # Prepare and execute insert
  my $sth = eval {
    my $prep = $dbh->prepare(
      'SELECT r.*,
        f.name AS folder_name,
        c.name AS category_name
      FROM resource r
      LEFT JOIN folder f ON r.folder_id = f.folder_id
      LEFT JOIN category c ON r.category_id = c.category_id
      WHERE r.user_id = ?'
    );
    $prep->execute($user_id);
    $prep;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Fetching resources failed: ' . $@},
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

  my $username = $c->session('login_name');
  my $email = $c->session('email');

  unless ($username) {
    return $c->render(
      json => {error => 'User not authenticated'},
      status => 401
    );
  }

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

  my $user_id = $user_row->{user_id};

  # Prepare and execute insert
  my $sth = eval {
    my $prep = $dbh->prepare(
      'INSERT INTO resource (link, name, type, description, owner, session, semester, user_id, folder_id, category_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $prep->execute(
      $resource->{link},
      $resource->{name},
      $resource->{type},
      $resource->{description},
      $email,
      $resource->{session},
      $resource->{semester},
      $user_id,
      $resource->{folder},
      $resource->{category}
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

sub updateResource {
  my $c = shift;

  my $resource = $c->req->json;
  my $resource_id = $c->stash('id');  # Get resource ID from URL

  my $username = $c->session('login_name');
  my $email = $c->session('email');

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

  # Prepare and execute update
  my $sth = eval {
    my $prep = $dbh->prepare(
      'UPDATE resource
        SET link = ?, name = ?, type = ?, description = ?,
          session = ?, semester = ?, folder_id = ?, category_id = ?
        WHERE resource_id = ? AND user_id = (SELECT user_id FROM user WHERE username = ?)'
    );
    $prep->execute(
      $resource->{link},
      $resource->{name},
      $resource->{type},
      $resource->{description},
      $resource->{session},
      $resource->{semester},
      $resource->{folder},
      $resource->{category},
      $resource_id,
      $username
    );
    $dbh->commit;
    $prep;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Update failed: ' . $@},
      status => 500
    );
  }

  $dbh->disconnect;

  # Check if any rows were updated
  if ($sth->rows == 0) {
    return $c->render(
      json => {error => 'Resource not found or unauthorized'},
      status => 404
    );
  }

  # Return success response
  $c->render(
    json => {
      message => 'Resource updated successfully',
      resource_id => $resource_id
    },
    status => 200
  );
}

sub deleteResource {
  my $c = shift;

  my $resource_id = $c->stash('id');  # Get resource ID from URL
  my $username = $c->session('login_name');

  unless ($username) {
    return $c->render(
      json => {error => 'User not authenticated'},
      status => 401
    );
  }

  unless ($resource_id) {
    return $c->render(
      json => {error => 'Missing resource ID'},
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

  # Prepare and execute delete
  my $sth = eval {
    my $prep = $dbh->prepare(
      'DELETE FROM resource
        WHERE resource_id = ? AND user_id = (SELECT user_id FROM user WHERE username = ?)'
    );
    $prep->execute($resource_id, $username);
    $dbh->commit;
    $prep;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Delete failed: ' . $@},
      status => 500
    );
  }

    $dbh->disconnect;

  # Check if any rows were deleted
  if ($sth->rows == 0) {
    return $c->render(
      json => {error => 'Resource not found or unauthorized'},
      status => 404
    );
  }

  # Return success response
  $c->render(
    json => {
      message => 'Resource deleted successfully',
      resource_id => $resource_id
    },
    status => 200
  );
}

1;
