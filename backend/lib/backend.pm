package backend;
use Mojo::Base 'Mojolicious', -signatures;
use Data::Dumper;

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  # Configure session management
  $self->sessions->cookie_name('gdrsms_session');
  $self->sessions->default_expiration(28800);  # 8 hours
  $self->sessions->secure(1);
  $self->sessions->samesite('None');

  # Configure the application
  $self->secrets($config->{secrets});

  # Enable CORS globally
  $self->hook(before_dispatch => sub {
    my $c = shift;
    $c->res->headers->header('Access-Control-Allow-Origin' => 'http://localhost:5173');
    $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, OPTIONS');
    $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
    $c->res->headers->header('Access-Control-Allow-Credentials' => 'true');
  });

  # Router
  my $r = $self->routes;

  # Handle preflight requests
  $r->options('*')->to(cb => sub ($c) {
    $c->res->headers->header('Access-Control-Allow-Origin' => 'http://localhost:5173');
    $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, OPTIONS, PUT, DELETE');
    $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
    $c->res->headers->header('Access-Control-Allow-Credentials' => 'true');
    $c->res->headers->header('Access-Control-Max-Age' => '86400');
    $c->render(text => '', status => 204);
  });

  # Normal routes to controller
  $r->get('/')->to('Example#welcome');
  $r->post('/api/users/register')->to('User#register');
  $r->post('/api/users/login')->to('Login#login');
  $r->post('/api/users/logout')->to('Login#logout');

  # Protected routes
  my $authorized = $r->under(sub ($c) {
    # Detailed logging for debugging
    $c->app->log->debug("Session contents: " . Dumper($c->session));
    $c->app->log->debug("Logged in status: " . ($c->session('logged_in') // 'Not set'));

    # Check if user is logged in
    if ($c->session('logged_in')) {
      return 1;
    }

    # Unauthorized access
    $c->render(
      json => {
        success => \0,
        message => 'Unauthorized access. Please log in.'
      },
      status => 401
    );
    return 0;
  });

  # Resource
  $authorized->get('/api/resources')->to('Resource#getAllResources');
  $authorized->post('/api/resources')->to('Resource#addResource');
  $authorized->put('/api/resources/:id')->to('Resource#updateResource');
  $authorized->delete('/api/resources/:id')->to('Resource#deleteResource');
  $authorized->post('/api/resources/share')->to('Resource#shareResource');

  # Shared Resource
  $authorized->get('/api/resource/statistics')->to('SharedResource#getResourceStatistics');
  $authorized->get('/api/resources/shared')->to('SharedResource#getAllSharedResources');
  $authorized->delete('/api/resources/shared/delete')->to('SharedResource#deleteSharedResource');
  $authorized->get('/api/resources/:resource_id/shared-users')->to('SharedResource#getSharedUsers');
  $authorized->post('/api/resources/unshare')->to('SharedResource#unshareResource');

  # Category
  $authorized->get('/api/categories')->to('Category#getAllCategories');
  $authorized->post('/api/categories')->to('Category#addCategory');
  $authorized->put('/api/categories/:id')->to('Category#updateCategory');
  $authorized->delete('/api/categories/:id')->to('Category#deleteCategory');

  # Folder
  $authorized->get('/api/folders')->to('Folder#getAllFolders');
  $authorized->get('/api/users')->to('User#getAllUsers');
  $authorized->get('/api/user/profile')->to('Setting#getUserProfile');

  # User Group
  $authorized->get('/api/groups')->to('UserGroup#getAllUserGroups');
  $authorized->post('/api/groups')->to('UserGroup#createGroup');
  $authorized->post('/api/groups/:group_id/leave')->to('UserGroup#leaveGroup');
  $authorized->delete('/api/groups/:group_id')->to('UserGroup#deleteGroup');
  $authorized->put('/api/groups/:group_id')->to('UserGroup#updateGroup');

  # Group Resource
  $authorized->get('/api/groups/:group_id/resources')->to('GroupResource#getGroupResources');
  $authorized->post('/api/groups/resources/share')->to('GroupResource#shareResourceWithGroup');
  $authorized->delete('/api/groups/:group_id/resources/delete')->to('GroupResource#removeResourceFromGroup');
  $authorized->post('/api/resources/share-with-groups-and-users')->to('GroupResource#shareResourceWithGroupAndUsers');
  $authorized->post('/api/resources/unshare-group')->to('GroupResource#unshareResourceFromGroup');
  $authorized->get('/api/resources/:resource_id/shared-groups')->to('GroupResource#getSharedGroups');

  # Group Member
  $authorized->get('/api/groups/:group_id/members')->to('GroupMember#getGroupMembers');
  $authorized->post('/api/groups/:group_id/members/add')->to('GroupMember#addGroupMembers');
  $authorized->delete('/api/groups/:group_id/members/remove')->to('GroupMember#removeGroupMember');

  # Admin
  $authorized->get('/api/admin/resources')->to('Admin#getAllResources');
}

1;
