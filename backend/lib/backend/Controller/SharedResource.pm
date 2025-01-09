package backend::Controller::SharedResource;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';
use Data::Dumper;

sub getResourceStatistics {
  my $c = shift;

  # Get the username and email from the session
  my $username = $c->session('login_name');
  my $user_email = $c->session('email');
    $c->app->log->debug("Session contents: " . Dumper($username));

  unless ($username && $user_email) {
    return $c->render(
      json => { error => 'User not authenticated' },
      status => 401
    );
  }

  # Load database configuration
  my $config = eval { LoadFile('config/database.yml') };
  if ($@) {
    return $c->render(
      json => { error => 'Could not load database configuration' },
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
      json => { error => 'Database connection failed: ' . $@ },
      status => 500
    );
  }

  # Query total shared resources and user-uploaded resources using the email
  my $total_shared_resources = $dbh->selectrow_array('SELECT
        COUNT(*)
      FROM
        resource r
      JOIN
        user_resource ur ON r.resource_id = ur.resource_id
      JOIN
        user u ON r.user_id = u.user_id
      WHERE
        ur.user_id = (SELECT user_id FROM user WHERE username = ?)', undef, $username);
  my $user_uploaded_resources = $dbh->selectrow_array(
    "SELECT COUNT(*) FROM resource WHERE owner = ?", undef, $user_email
  );

  # Return statistics as JSON
  return $c->render(
    json => {
      total_shared_resources => $total_shared_resources || 0,
      user_uploaded_resources => $user_uploaded_resources || 0,
    }
  );
}

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
        r.semester,
        c.name AS category_name
      FROM
        resource r
      JOIN
        user_resource ur ON r.resource_id = ur.resource_id
      JOIN
        user u ON r.user_id = u.user_id
      LEFT JOIN
        category c ON r.category_id = c.category_id
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

sub deleteSharedResource {
  my $c = shift;

  # Get the username from the session
  my $username = $c->session('login_name');
  my $resource_data = $c->req->json;

  unless ($username) {
    return $c->render(
      json => {error => 'User not authenticated'},
      status => 401
    );
  }

  unless ($resource_data->{resource_id}) {
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
      'DELETE FROM user_resource
      WHERE resource_id = ? AND user_id = (SELECT user_id FROM user WHERE username = ?)'
    );
    $prep->execute($resource_data->{resource_id}, $username);
    $dbh->commit;
    $prep;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Delete shared resource failed: ' . $@},
      status => 500
    );
  }

  $dbh->disconnect;

  # Check if any rows were deleted
  if ($sth->rows == 0) {
    return $c->render(
      json => {error => 'Resource not found or not shared with you'},
      status => 404
    );
  }

  # Return success response
  $c->render(
    json => {
      message => 'Shared resource removed successfully',
      resource_id => $resource_data->{resource_id}
    },
    status => 200
  );
}

sub getSharedUsers {
  my $c = shift;
  my $resource_id = $c->param('resource_id');

  # Get the username from the session for authorization
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

  # Verify resource ownership or sharing
  my $is_owner_or_shared = $dbh->selectrow_array(
    'SELECT 1
      FROM resource r
      JOIN user u ON r.user_id = u.user_id
      WHERE r.resource_id = ? AND (u.username = ? OR EXISTS (
        SELECT 1
        FROM user_resource ur
        JOIN user sharing_user ON ur.user_id = sharing_user.user_id
        WHERE ur.resource_id = r.resource_id AND sharing_user.username = ?
      ))',
    undef,
    $resource_id,
    $username,
    $username
  );

  unless ($is_owner_or_shared) {
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Not authorized to view shared users'},
      status => 403
    );
  }

  # Query to fetch shared users
  my $sth = $dbh->prepare(
    'SELECT u.user_id, u.email
      FROM user u
      JOIN user_resource ur ON u.user_id = ur.user_id
      WHERE ur.resource_id = ?'
  );
  $sth->execute($resource_id);

  my $shared_users = $sth->fetchall_arrayref({});
  $sth->finish;
  $dbh->disconnect;

  $c->render(json => $shared_users);
}

sub unshareResource {
  my $c = shift;
  my $resource_data = $c->req->json;

  # Get the username from the session
  my $username = $c->session('login_name');

  unless ($username) {
    return $c->render(
      json => {error => 'User not authenticated'},
      status => 401
    );
  }

  # Validate input
  unless ($resource_data->{resource_id} && $resource_data->{user_id}) {
    return $c->render(
      json => {error => 'Missing resource ID or user ID'},
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

  # Verify resource ownership
  my $is_owner = $dbh->selectrow_array(
    'SELECT 1
      FROM resource r
      JOIN user u ON r.user_id = u.user_id
      WHERE r.resource_id = ? AND u.username = ?',
    undef,
    $resource_data->{resource_id},
    $username
  );

  unless ($is_owner) {
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Not authorized to unshare this resource'},
      status => 403
    );
  }

  # Prepare and execute unshare
  my $sth = $dbh->prepare(
    'DELETE FROM user_resource
      WHERE resource_id = ? AND user_id = ?'
  );
  $sth->execute($resource_data->{resource_id}, $resource_data->{user_id});
  $dbh->commit;

  $dbh->disconnect;

  # Check if any rows were deleted
  if ($sth->rows == 0) {
    return $c->render(
      json => {error => 'Resource not shared with specified user'},
      status => 404
    );
  }

  # Return success response
  $c->render(
    json => {
      message => 'Resource unshared successfully',
      resource_id => $resource_data->{resource_id},
      user_id => $resource_data->{user_id}
    },
    status => 200
  );
}


1;
