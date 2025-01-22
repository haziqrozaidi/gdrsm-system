package backend::Controller::Logs;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';
use DBI;
use POSIX qw(strftime);
use Data::Dumper;

# Log user activity
sub log_activity {
    my $c = shift;

    # Retrieve user_id from session
    my $username = $c->session('login_name');    
    my $username2 = $c->session('full_name');
    $c->app->log->debug("Log contents: " . Dumper($username,$username2));
    unless ($username || $username2) {
        return $c->render(
            json => { error => 'User not authenticated' },
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
    my $result;
    my $sth;
    my $user_id = eval {
        if(defined $username){
        $sth = $dbh->prepare(
        'SELECT user_id
         FROM user
         WHERE username = ?'
        );
    $sth->execute($username);
    }
        else{
        $sth = $dbh->prepare(
        'SELECT user_id
         FROM user
         WHERE full_name = ?'
        );
    $sth->execute($username2);
    }    
    $result = $sth->fetchrow_arrayref();  # Fetch the first row as an array reference
    # If a result is found, return the user_id (first element of the array reference)
    if ($result) {
        $c->app->log->debug("User ID: " . $result->[0]);  # Log the user_id
        return $result->[0];  # Return the user_id directly (scalar value)
    } else {
        $c->app->log->debug("User not found.");
        return undef;  # If no user is found, return undef
    }
    };
    # Get action and resource_name from request
    # Get action and resource_name from JSON request body
    my $data = $c->req->json;
    my $action = $data->{action};
    my $resource_name = $data->{resource_name};

    # Get the current timestamp in the correct format for MySQL
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);

    unless ($action && $resource_name) {
        return $c->render(
        json => { error => 'Missing required parameters' },
        status => 400
    );
    }


    # Log activity (example with mock database or logging logic)
    my $log_entry = {
        user_id       => $user_id,
        action        => $action,
        resource_name => $resource_name,
        timestamp     => $timestamp,
    };

    my $ssth = $dbh->prepare(
    'INSERT INTO logs (user_id, action, resource_name, timestamp) VALUES (?, ?, ?, ?)'
    );
    $ssth->execute(
    $log_entry->{user_id},
    $log_entry->{action},
    $log_entry->{resource_name},
    $log_entry->{timestamp}
    );
    $dbh->commit;
    $c->render(
        json => { success => 1, message => 'Activity logged successfully' },
        status => 200
    );
    $dbh->disconnect;
}


# Fetch recent activities
sub get_recent_activities {
    my $c = shift;
    # Retrieve user_id from session
    my $username = $c->session('login');    
    my $username2 = $c->session('full_name');
    unless ($username || $username2) {
        return $c->render(
            json => { error => 'User not authenticated' },
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
    my $sth;
    my $user_id = eval {
        if(defined $username){
    $sth = $dbh->prepare(
        'SELECT user_id
         FROM user
         WHERE login_name = ?'
    );
    $sth->execute($username);
        }else{
            $sth = $dbh->prepare(
        'SELECT user_id
         FROM user
         WHERE full_name = ?'
    );
    $sth->execute($username2);
        }
    my $result = $sth->fetchrow_arrayref();  # Fetch the first row as an array reference
    
    # If a result is found, return the user_id (first element of the array reference)
    if ($result) {
        $c->app->log->debug("User ID: " . $result->[0]);  # Log the user_id
        return $result->[0];  # Return the user_id directly (scalar value)
    } else {
        $c->app->log->debug("User not found.");
        return undef;  # If no user is found, return undef
    }
    };

    # Fetch logs
    my $logs = eval {
        my $sth = $dbh->prepare(
            'SELECT action, resource_name, timestamp
             FROM logs
             WHERE user_id = ?
             ORDER BY timestamp DESC
             LIMIT 10'
        );
        $sth->execute($user_id);
        $sth->fetchall_arrayref({});
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => { error => 'Failed to fetch logs: ' . $@ },
            status => 500
        );
    }
    $dbh->commit;
    $dbh->disconnect;
    $c->render(json => $logs);
}

1;