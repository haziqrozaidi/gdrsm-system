package backend::Controller::AdminUser;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;
use YAML::XS 'LoadFile';
use Data::Dumper;
# Fetch all users (Admin only)
sub fetchAllUsers {
    my $c = shift;
    my $username = $c->session('login_name');
    my $role = $c->session('role');
    my $description =$c->session('description');
    $c->app->log->debug("Session data: " . $c->dumper($c->session));
    $c->app->log->debug("Checking role: " . ($role // 'undefined'));

    # Ensure the requester is an admin
    unless ($role && lc($role) eq 'admin') {
        return $c->render(
            json => {error => 'Unauthorized access. Admins only.'},
            status => 403
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

    # Fetch all users
    my $sth = eval {
        my $prep = $dbh->prepare('SELECT * FROM user');
        $prep->execute();
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching users failed: ' . $@},
            status => 500
        );
    }

    my $users = $sth->fetchall_arrayref({});
    $sth->finish;

    $dbh->disconnect;

    # Return the list of users
    $c->render(json => $users);
}

sub updateUserRole {
    my $c = shift;
    my $username = $c->session('login_name');
    my $role = $c->session('role');
    my $description =$c->session('description');
    $c->app->log->debug("Session data: " . $c->dumper($c->session));
    $c->app->log->debug("Checking role: " . ($role // 'undefined'));
    # Ensure the requester is an admin
    unless ($role && $role eq 'Admin') {
        return $c->render(
            json => {error => 'Unauthorized access. Admins only.'},
            status => 403
        );
    }

    # Get user ID and new role from request
    my $data = $c->req->json;
    my $full_name = $data->{full_name};
    my $new_role = $data->{role};

    unless ($full_name && $new_role) {
        return $c->render(
            json => {error => 'Missing user_id or role'},
            status => 400
        );
    }

    # Only allow role change to "Admin" if current role is "Pensyarah"
    unless ($new_role eq 'Admin') {
        return $c->render(
            json => {error => 'Role can only be updated to Admin for Pensyarah.'},
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

    # Update user role
    my $sth = eval {
        my $prep = $dbh->prepare('UPDATE user SET role = ? WHERE full_name = ?');
        $prep->execute($new_role, $full_name);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Updating role failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(json => {message => 'Role updated successfully'});
}



1;
