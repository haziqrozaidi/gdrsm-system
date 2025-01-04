package backend::Controller::GroupResource;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use YAML::XS 'LoadFile';

sub getGroupResources {
    my $c = shift;

    # Get group_id from URL parameter
    my $group_id = $c->stash('group_id');

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

    # Verify user's membership in the group
    my $membership_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT 1 FROM group_members gm
             JOIN user u ON gm.user_id = u.user_id
             WHERE gm.group_id = ? AND u.username = ?'
        );
        $prep->execute($group_id, $username);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Membership check failed: ' . $@},
            status => 500
        );
    }

    unless ($membership_sth->fetchrow_array) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'User is not a member of this group'},
            status => 403
        );
    }

    # Fetch group resources
    my $resources_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT r.resource_id, r.name, r.type, r.description, r.link,
                    r.owner, r.session, r.semester, r.date_created,
                    f.name AS folder_name,
                    c.name AS category_name
             FROM group_resource gr
             JOIN resource r ON gr.resource_id = r.resource_id
             LEFT JOIN folder f ON r.folder_id = f.folder_id
             LEFT JOIN category c ON r.category_id = c.category_id
             WHERE gr.group_id = ?'
        );
        $prep->execute($group_id);
        $prep;
    };

    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching group resources failed: ' . $@},
            status => 500
        );
    }

    my $resources = $resources_sth->fetchall_arrayref({});
    $resources_sth->finish;

    $dbh->disconnect;

    # Return resources
    $c->render(json => $resources);
}


1;
