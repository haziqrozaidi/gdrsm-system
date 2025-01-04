package backend::Controller::GroupMember;
use DBI;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use YAML::XS 'LoadFile';

sub getGroupMembers {
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

    # Fetch group members
    my $members_sth = eval {
        my $prep = $dbh->prepare(
            'SELECT
                u.user_id,
                u.username,
                u.email,
                u.full_name,
                u.faculty,
                u.role,
                gm.date_joined
            FROM group_members gm
            JOIN user u ON gm.user_id = u.user_id
            WHERE gm.group_id = ?'
        );
        $prep->execute($group_id);
        $prep;
    };


    if ($@) {
        $dbh->disconnect;
        return $c->render(
            json => {error => 'Fetching group members failed: ' . $@},
            status => 500
        );
    }

    my $members = $members_sth->fetchall_arrayref({});
    $members_sth->finish;

    $dbh->disconnect;

    # Return members
    $c->render(json => $members);
}

1;
