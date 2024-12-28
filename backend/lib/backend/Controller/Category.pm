package backend::Controller::Category;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use YAML::XS 'LoadFile';

sub getAllCategories {
    my $c = shift;

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
            json => {error => 'Database connection failed: ' .$@},
            status => 500
        );
    }

    my $sth = eval {
        my $prep = $dbh->prepare(
            'SELECT * FROM category'
        );
        $prep->execute;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching categories failed: ' . $@},
            status => 500
        );
    }

    my $categories = $sth->fetchall_arrayref({});
    $sth->finish;

    $dbh->disconnect;

    $c->render(json => $categories)
}

sub addCategory {
    my $c = shift;

    # Get the category data from the request
    my $category_data = $c->req->json;

    # Validate input
    unless ($category_data->{name}) {
        return $c->render(
            json => {error => 'Category name is required'},
            status => 400
        );
    }

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

    # Check if category already exists
    my $check_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM category WHERE name = ?'
        );
        $prep->execute($category_data->{name});
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category check failed: ' . $@},
            status => 500
        );
    }

    if ($check_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category with this name already exists'},
            status => 409
        );
    }

    # Prepare insert statement
    my $sth = eval {
        my $prep = $dbh->prepare(
            'INSERT INTO category (name, description) VALUES (?, ?)'
        );
        $prep->execute(
            $category_data->{name},
            $category_data->{description} || ''
        );
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Adding category failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Category added successfully',
            name => $category_data->{name}
        },
        status => 201
    );
}

1;
