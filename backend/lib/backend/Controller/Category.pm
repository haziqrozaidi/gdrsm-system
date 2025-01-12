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
$c->session('login_name');
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

sub updateCategory {
    my $c = shift;

    # Get category ID from URL parameter
    my $category_id = $c->stash('id');

    # Get the category data from the request
    my $category_data = $c->req->json;

    # Validate input
    unless ($category_id) {
        return $c->render(
            json => {error => 'Category ID is required'},
            status => 400
        );
    }

    unless ($category_data->{name}) {
        return $c->render(
            json => {error => 'Category name is required'},
            status => 400
        );
    }

    # Check user authentication
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

    # Check if category exists
    my $check_exist_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM category WHERE category_id = ?'
        );
        $prep->execute($category_id);
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category existence check failed: ' . $@},
            status => 500
        );
    }

    unless ($check_exist_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category not found'},
            status => 404
        );
    }

    # Check for duplicate category name (excluding current category)
    my $check_name_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM category WHERE name = ? AND category_id != ?'
        );
        $prep->execute($category_data->{name}, $category_id);
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category name check failed: ' . $@},
            status => 500
        );
    }

    if ($check_name_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category with this name already exists'},
            status => 409
        );
    }

    # Prepare update statement
    my $sth = eval {
        my $prep = $dbh->prepare(
            'UPDATE category SET name = ?, description = ? WHERE category_id = ?'
        );
        $prep->execute(
            $category_data->{name},
            $category_data->{description} || '',
            $category_id
        );
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Updating category failed: ' . $@},
            status => 500
        );
    }

    # Check if any rows were updated
    my $rows_affected = $sth->rows;

    $dbh->disconnect;

    if ($rows_affected == 0) {
        return $c->render(
            json => {error => 'No changes made to the category'},
            status => 304
        );
    }

    # Return success response
    $c->render(
        json => {
            message => 'Category updated successfully',
            category_id => $category_id,
            name => $category_data->{name},
            description => $category_data->{description}
        },
        status => 200
    );
}

sub deleteCategory {
    my $c = shift;

    # Get category ID from URL parameter
    my $category_id = $c->stash('id');

    # Validate input
    unless ($category_id) {
        return $c->render(
            json => {error => 'Category ID is required'},
            status => 400
        );
    }

    # Check user authentication
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

    # Check if category exists
    my $check_exist_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM category WHERE category_id = ?'
        );
        $prep->execute($category_id);
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category existence check failed: ' . $@},
            status => 500
        );
    }

    unless ($check_exist_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category not found'},
            status => 404
        );
    }

    # Check if category is used in any resources
    my $check_usage_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT COUNT(*) FROM resource WHERE category_id = ?'
        );
        $prep->execute($category_id);
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Category usage check failed: ' . $@},
            status => 500
        );
    }

    my ($resource_count) = $check_usage_sth->fetchrow_array;

    if ($resource_count > 0) {
        $dbh->disconnect;
        return $c->render(
            json => {
                error => "Cannot delete category. It is used by $resource_count resource(s).",
                resource_count => $resource_count
            },
            status => 409
        );
    }

    # Prepare delete statement
    my $sth = eval {
        my $prep = $dbh->prepare(
            'DELETE FROM category WHERE category_id = ?'
        );
        $prep->execute($category_id);
        $dbh->commit;
        $prep;
    };

    if ($@) {
        $dbh->rollback;
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Deleting category failed: ' . $@},
            status => 500
        );
    }

    $dbh->disconnect;

    # Return success response
    $c->render(
        json => {
            message => 'Category deleted successfully',
            category_id => $category_id
        },
        status => 200
    );
}

1;
