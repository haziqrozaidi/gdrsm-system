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
            json => {error => 'Missing full name and role'},
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
    
    # Invalidate session if the current user's role is updated
    if ($c->session('full_name') eq $full_name && lc($new_role) eq 'pensyarah') {
        $c->session(expires => 1); # Invalidate session
        return $c->render(
            json => {
                success => 1,
                message => 'Role updated. Current session invalidated.',
                logged_out => 1
            }
        );

    }
    # Return success response
    $c->render(json => {message => 'Role updated successfully'});
}

sub checkUserDependencies {
    my $c = shift;

    # Ensure the requester is an admin
    my $role = $c->session('role');
    unless ($role && $role eq 'Admin') {
        return $c->render(
            json => {error => 'Unauthorized access. Admins only.'},
            status => 403
        );
    }

    # Get user ID from the JSON payload
    my $payload = $c->req->json;
    my $user_id = $payload->{user_id};
    unless ($user_id) {
        return $c->render(
            json => {error => 'User ID is required in the payload'},
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

    # Check for dependencies
    my $dependencies = eval {
        my $prep = $dbh->prepare(
            'SELECT COUNT(*) AS resource_count FROM resource WHERE user_id = ?'
        );
        $prep->execute($user_id);
        $prep->fetchrow_hashref;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Failed to check dependencies: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return dependency count
    $c->render(
        json => {
            hasDependencies => $dependencies->{resource_count} > 0,
            resourceCount   => $dependencies->{resource_count}
        },
        status => 200
    );
}
sub deleteUser {
    my $c = shift;

    # Ensure the requester is an admin
    my $role = $c->session('role');
    unless ($role && $role eq 'Admin') {
        return $c->render(
            json => {error => 'Unauthorized access. Admins only.'},
            status => 403
        );
    }

    # Get user ID from the JSON
    my $payload = $c->req->json;
    my $user_id = $payload->{user_id};
    unless ($user_id) {
        return $c->render(
            json => {error => 'User ID is required in the payload'},
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

    # Delete the user
    eval {
        # Optional: Delete associated resources (or let database constraints handle it)
        my $delete_resources = $dbh->prepare('DELETE FROM resource WHERE user_id = ?');
        $delete_resources->execute($user_id);

        # Delete the user
        my $delete_user = $dbh->prepare('DELETE FROM user WHERE user_id = ?');
        $delete_user->execute($user_id);

        $dbh->commit;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Failed to delete user: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'User deleted successfully'
        },
        status => 200
    );
}
1;
