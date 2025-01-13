package backend::Controller::Resource;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';
use Data::Dumper;

sub getAllResources {
  my $c = shift;

  # Get the username and role from the session
  my $username = $c->session('login_name');
  my $role = $c->session('role');
  my $description =$c->session('description');
  unless ($username && ($role || $description)) {
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

  # Base SQL query to fetch resources
  my $query = qq{
    SELECT r.resource_id, 
           r.link, 
           r.name, 
           r.type, 
           r.description, 
           r.owner, 
           r.date_created, 
           r.session, 
           r.semester, 
           r.user_id, 
           f.name AS folder_name, 
           c.name AS category_name
    FROM resource r
    LEFT JOIN folder f ON r.folder_id = f.folder_id
    LEFT JOIN category c ON r.category_id = c.category_id
  };

  # Modify query for non-admin users
  if ($role ne 'Admin') {
    $query .= " WHERE r.user_id = (SELECT user_id FROM user WHERE username = ?)";
  }

  # Prepare and execute the query
  my $sth = eval {
    my $prep = $dbh->prepare($query);
    if (($role || $description) eq 'Admin') {
      $prep->execute(); # Admin fetches all resources
    } else {
      $prep->execute($username); # Normal users fetch only their resources
    }
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

sub shareResource {
  my $c = shift;

  my $data = $c->req->json;
  my $resource_id = $data->{resource_id};
  my @user_ids = @{$data->{user_ids}};

  # Get current user
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

  # Verify resource ownership
  my $check_ownership_sth = $dbh->prepare(
    'SELECT 1 FROM resource r 
      JOIN user u ON r.user_id = u.user_id 
      WHERE r.resource_id = ? AND u.username = ?'
  );
  $check_ownership_sth->execute($resource_id, $username);

  unless ($check_ownership_sth->fetchrow_array) {
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Unauthorized to share this resource'},
      status => 403
    );
  }

  # Prepare to insert shared resources
  my $insert_sth = $dbh->prepare(
    'INSERT INTO user_resource (user_id, resource_id) VALUES (?, ?)'
  );

  # Share resource with selected users
  eval {
    foreach my $user_id (@user_ids) {
      $insert_sth->execute($user_id, $resource_id);
    }
    $dbh->commit;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Failed to share resource: ' . $@},
      status => 500
    );
  }

  $dbh->disconnect;

  # Return success response
  $c->render(
    json => {
      message => 'Resource shared successfully',
      shared_with_count => scalar @user_ids
    },
    status => 200
  );
}

1;
