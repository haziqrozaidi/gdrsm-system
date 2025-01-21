package backend::Controller::User;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';

sub register ($c, $user, $password) {
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
      VALUES (?, ?, ?, ?, ?, ?)'
    );
    $prep->execute(
      $user->{login_name},
      $user->{full_name},
      $user->{email},
      $password,
      $user->{description},
      ''
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

  # Create a default folder
  my $folder_sth = eval {
    my $prep = $dbh->prepare(
      'INSERT INTO folder (name, description, user_id)
        SELECT ?, ?, user_id
        FROM user
        WHERE username = ?'
    );
    $prep->execute(
      'My Folder',
      'A default folder to store and organize your resources',
      $user->{login_name}
    );
    $dbh->commit;
    $prep;
  };

  if ($@) {
    $dbh->rollback;
    $dbh->disconnect;
    return $c->render(
      json => {error => 'Creating folder failed: ' . $@},
      status => 500
    );
  }

  $dbh->disconnect;

  # Create a session
  $c->session(
    full_name   => $user->{full_name},
    description => $user->{description},
    login_name  => $user->{login_name},
    email       => $user->{email},
    logged_in   => 1,
    expiration  => time + (8 * 60 * 60)  # 8 hours
  );

  # Return success response with user details
  $c->render(
    json => {
      success     => \1,
      full_name   => $user->{full_name},
      description => $user->{description},
      login_name  => $user->{login_name},
      email       => $user->{email}
    },
    status => 201
  );
}

sub getAllUsers {
  my $c = shift;

  # Similar database connection logic as in other methods
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

  my $sth = $dbh->prepare(
    'SELECT user_id, username, full_name, email FROM user'
  );
  $sth->execute();

  my $users = $sth->fetchall_arrayref({});

  $c->render(json => $users);
}

1;
