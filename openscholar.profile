<?php
// $Id$

/**
 * Implementation of hook_profile_details().
 */
function openscholar_profile_details() {
  return array(
    'name' => 'OpenScholar',
    'description' => 'OpenScholar distribution by IQSS at Harvard'
  );
}

/**
 * Implementation of hook_profile_modules().
 */
function openscholar_profile_modules() {
  return array(
    //core
    'block', 'book', 'comment', 'contact', 'filter', 'help',
    'menu', 'node', 'system', 'search', 'user', 'path', 'php',
    'taxonomy', 'upload',
  
    //admin menu
    'admin_menu',
    //views
    'views',
    //og
    'og', 'og_access', 'og_actions', 'og_views', 'og_vocab',
    //ctools
    'ctools',
    // context
    'context', 'context_contrib', 'context_ui',
    // date
    'date_api', 'date_timezone',
    // features
    'features',
    // image
    'imageapi', 'imageapi_gd', 'imagecache',
    // token
    'token',
    // transliteration
    'transliteration',
    // purl
    'purl',
    // spaces
    'spaces', 'spaces_og',
    // ucreate
    'ucreate', 'ucreate_og',
  
    
  );
}

/**
 * Returns an array list of core contributed modules.
 */
function _openscholar_core_modules() {
 $contrib_modules = array(

    'addthis',
    'advanced_help',
    'install_profile_api',
    'content',
 
    'biblio',
    'auto_nodetitle',
    'content_copy',
    'content_profile',
    'diff',
 
    'flag',
    'jquery_update',
    'jquery_ui',
    'lightbox2',
    'litecal',
    'menu_node',
    'override_node_options',
    'schema',
    'stringoverrides',
    'strongarm',
    'twitter_pull',

    'vertical_tabs',
    'itweak_upload',

    'wysiwyg',
    'activity',

    'content_profile_registration',

    'data',

    'dialog',
    'dyntextfield',
    'feeds',
    'feeds_defaults',
    'fieldgroup',
    'filefield',
    'filefield_paths',
    'imagecache_ui',
    'imagefield',
    'imagefield_crop',
    'link',
    'number',

    'optionwidgets',
    'pathauto',


    'text',

    'views_attach',
    'views_bulk_operations',
    'views_export',
    'views_ui',
 
    'data_node',
    'data_ui',
    'date',
    'date_popup',
    'file_aliases',
    'nodereference',
    'nodereference_url',

   // signup
    'signup',
    'signup_confirm_email',
  );
  
  return $contrib_modules;
}

/**
 * Returns an array list of openscholar specific modules.
 */
function _openscholar_scholar_modules() {
  return array(
    'vsite',
    'vsite_widgets',
    //'scholar',
    'vsite_content',
    'vsite_domain',
    'scholar_events',
    'scholar_events_signup',
    'vsite_ga',
    'vsite_layout',
    'vsite_menus',
    'vsite_design',
    'vsite_users',
    'vsite_taxonomy',
    'vsitehelp',
    'vsite_news',
    'vsite_support',

    'vsite_generic_settings',
    'vsite_comments',
    
    'cp',
    'bkn',
    'cite_distribute',
    'repec_meta',
    'googlescholar_meta',

  
    //Install-Wide Pages
    'scholarregister',
    'openscholar_front',

    // features
    'scholar_dvn',
    'scholar_links',
    'scholar_blog',
    'scholar_book',
    'scholar_announcements',
    'scholar_classes',
    'scholar_image_gallery',
    'scholar_publications',
    'scholar_software',
    'scholar_pages',
    'scholar_reader',
    'scholar_front',
    'scholar_profiles',
  );
}

/**
 * Implementation of hook_profile_task_list().
 */
function openscholar_profile_task_list() {
  global $conf;
  $conf['site_name'] = 'OpenScholar';
  $conf['site_footer'] = '<a href="http://openscholar.harvard.edu">OpenScholar</a> by <a href="http://iq.harvard.edu">IQSS</a> at Harvard University';
  
  
  $tasks = array(
    'openscholar-flavor' => st('OpenScholar  flavor'),
    'openscholar-configure' => st('Openscholar  configuration'),
  );
  return $tasks;
}

/**
 * Implementation of hook_profile_tasks().
 */
function openscholar_profile_tasks(&$task, $url) {

  $output = '';

  if ($task == 'profile') {
    $modules = _openscholar_core_modules();
    $modules = array_merge($modules, _openscholar_scholar_modules());

    $files = module_rebuild_cache();
    $operations = array();
    foreach ($modules as $module) {
      $operations[] = array('_install_module_batch', array($module, $files[$module]->info['name']));
    }
    $batch = array(
    'operations' => $operations,
    'finished' => '_openscholar_profile_batch_finished',
    'title' => st('Installing @drupal', array('@drupal' => drupal_install_profile_name())),
    'error_message' => st('The installation has encountered an error.'),
    );
    // Start a batch, switch to 'profile-install-batch' task. We need to
    // set the variable here, because batch_process() redirects.
    variable_set('install_task', 'profile-install-batch');
    batch_set($batch);
    batch_process($url, $url);
  }
  
  // chose an openscholar flavor to install
  if ($task == 'openscholar-flavor') {
      $output = drupal_get_form('_openscholar_flavors_form', $url);
    if (! variable_get('openscholar_flavor_form_executed', FALSE)) {
      drupal_set_title('How will this OpenScholar installation be used?');
      return $output;
    }
    else {
      $task = 'openscholar-configure';
    }
  }

  // Run additional configuration tasks
  if ($task == 'openscholar-configure') {
    //Include Modules that have been enabled
    //We don't need to use install_include since the system table has been enabled
    module_load_all();
    
    // create roles
    _openscholar_create_roles();
    
    // create a default contact form
    _vsite_default_contact_form();
    
    // disable some flags
    _openscholar_flags();
    
    // configure wisywig/tinymce
    _openscholar_wysiwyg_config();

    // Rebuild key tables/caches
    menu_rebuild();
    module_rebuild_cache(); // Detects the newly added bootstrap modules
    node_access_rebuild();
    drupal_get_schema('system', TRUE); // Clear schema DB cache
    drupal_flush_all_caches();
    db_query("UPDATE {blocks} SET status = 0, region = ''"); // disable all DB blocks
    
    // create a global taxonomy (not really used right now)
    // _vsite_global_taxonomy();
    
    //filefield_path /alias config
    _openscholar_filefield_paths_config();
    
    // biblio configuraitons
    _openscholar_configure_biblio();
    
    if (function_exists('strongarm_init')) {
      strongarm_init();
    }

    variable_set('scholar_content_type', 'vsite');
    variable_set('site_frontpage', 'welcome');

    cache_clear_all();
    
    //Make theme modifications last so that clearing the cache here does not mess up our work
    
    //Reset Theme Info
    _openscholar_system_theme_data();
    
    // enable the themes
    _openscholar_enable_themes();
    
    // we are done let the installer know
    $task = 'profile-finished';
  }
  return $output;
}

/**
 * Finished callback for the modules install batch.
 *
 * Advance installer task to language import.
 */
function _openscholar_profile_batch_finished($success, $results) {
  //variable_set('install_task', 'openscholar-configure');
  variable_set('install_task', 'openscholar-flavor');
}

/**
 * enable a couple of themes
 */
function _openscholar_enable_themes(){
  
  $themes = array(
    'openscholar_default', //Default theme
    'zen',
    'cp_theme',
    'scholar_base',
    'scholar_airstream',
    'scholar_bigpic',
    'scholar_bunchy',
    'scholar_burroughs',
    'scholar_cayley',
    'scholar_collector',
    'scholar_density',
    'scholar_eloquent',
    'scholar_nortony',
    'scholar_quinn',
    'scholar_redhead',
    'scholar_stripy',
    'scholar_weft'
  );
  
  //enable the themes
  foreach($themes as $theme){
    db_query("UPDATE {system} SET status = 1 WHERE type = 'theme' and name = '%s'", $theme);
    system_initialize_theme_blocks($theme);
  }
  
  //Set default theme
  global $theme_key;
  variable_set('theme_default', 'openscholar_default');
  // update the global variable too,
  // mainly so that block functions work correctly
  $theme_key = $theme;
  
  // disable all DB blocks
  db_query("UPDATE {blocks} SET status = 0, region = ''");

}

/**
 * Create a default sitewide contact form using
 * 'site_mail' variable as email recipient
 */
function _vsite_default_contact_form(){
  $sitewide_contact_form = new stdClass();
  $sitewide_contact_form -> category = 'website feedback';
  $sitewide_contact_form -> recipients = variable_get('site_mail', '');
  $sitewide_contact_form -> selected = 1;
  if (strlen($sitewide_contact_form -> recipients)) {
    drupal_write_record('contact', $sitewide_contact_form);
  }
}

/**
 * disable the bookmarks flag
 */
function _openscholar_flags(){
  //disable the f. bookmarks flag
  module_load_include('inc', 'flag', '/includes/flag.admin');
  $flag = flag_get_flag('bookmarks');
  if(!$flag) return;
  $flag->delete();
  //$flag->disable();
  _flag_clear_cache();
}

/**
 *  Change the biblio Config
 */
function _openscholar_configure_biblio(){
  $s_common_string = <<<COMMON
a:6:{s:7:"storage";N;s:9:"submitted";b:1;s:6:"values";a:7:{s:17:"hide_other_fields";i:0;s:15:"configured_flds";a:53:{i:15;a:5:{s:5:"title";s:19:"Year of Publication";s:4:"hint";s:33:"Enter YYYY, Submitted or In Press";s:6:"weight";s:3:"-45";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";s:8:"required";s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"15";}i:53;a:5:{s:5:"title";s:0:"";s:4:"hint";s:0:"";s:6:"weight";s:1:"1";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"53";}i:22;a:5:{s:5:"title";s:8:"Abstract";s:4:"hint";s:0:"";s:6:"weight";s:1:"1";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"22";}i:1;a:6:{s:5:"title";s:7:"Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"2";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";s:8:"required";s:12:"autocomplete";s:12:"autocomplete";}s:5:"ftdid";s:1:"1";s:9:"auth_type";a:5:{i:1;s:1:"1";i:2;s:1:"2";i:3;s:1:"3";i:4;s:1:"4";i:5;s:1:"5";}}i:2;a:6:{s:5:"title";s:12:"Contributors";s:4:"hint";s:0:"";s:6:"weight";s:1:"3";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:12:"autocomplete";s:12:"autocomplete";s:8:"required";i:0;}s:5:"ftdid";s:1:"2";s:9:"auth_type";a:13:{i:10;s:2:"10";i:11;s:2:"11";i:12;s:2:"12";i:13;s:2:"13";i:14;s:2:"14";i:15;s:2:"15";i:16;s:2:"16";i:17;s:2:"17";i:18;s:2:"18";i:19;s:2:"19";i:20;s:2:"20";i:21;s:2:"21";i:22;s:2:"22";}}i:3;a:6:{s:5:"title";s:16:"Tertiary Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"3";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:1:"3";s:9:"auth_type";a:1:{i:3;s:1:"3";}}i:4;a:6:{s:5:"title";s:18:"Subsidiary Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"4";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:1:"4";s:9:"auth_type";a:1:{i:4;s:1:"4";}}i:5;a:6:{s:5:"title";s:17:"Corporate Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"5";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:1:"5";s:9:"auth_type";a:1:{i:5;s:1:"5";}}i:6;a:5:{s:5:"title";s:15:"Secondary Title";s:4:"hint";s:0:"";s:6:"weight";s:2:"12";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:1:"6";}i:7;a:5:{s:5:"title";s:14:"Tertiary Title";s:4:"hint";s:0:"";s:6:"weight";s:2:"13";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:1:"7";}i:17;a:5:{s:5:"title";s:6:"Volume";s:4:"hint";s:0:"";s:6:"weight";s:2:"14";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"17";}i:43;a:5:{s:5:"title";s:7:"Section";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"43";}i:37;a:5:{s:5:"title";s:17:"Number of Volumes";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"37";}i:28;a:5:{s:5:"title";s:5:"Issue";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"28";}i:16;a:5:{s:5:"title";s:7:"Edition";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"16";}i:18;a:5:{s:5:"title";s:6:"Number";s:4:"hint";s:0:"";s:6:"weight";s:2:"16";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"18";}i:19;a:5:{s:5:"title";s:10:"Pagination";s:4:"hint";s:0:"";s:6:"weight";s:2:"17";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"19";}i:20;a:5:{s:5:"title";s:14:"Date Published";s:4:"hint";s:9:"(mm/yyyy)";s:6:"weight";s:2:"18";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"20";}i:13;a:5:{s:5:"title";s:9:"Publisher";s:4:"hint";s:0:"";s:6:"weight";s:2:"19";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"13";}i:14;a:5:{s:5:"title";s:15:"Place Published";s:4:"hint";s:0:"";s:6:"weight";s:2:"20";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"14";}i:25;a:5:{s:5:"title";s:12:"Type of Work";s:4:"hint";s:14:"Masters Thesis";s:6:"weight";s:2:"22";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"25";}i:21;a:5:{s:5:"title";s:20:"Publication Language";s:4:"hint";s:0:"";s:6:"weight";s:2:"23";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"21";}i:12;a:5:{s:5:"title";s:25:"Other Author Affiliations";s:4:"hint";s:0:"";s:6:"weight";s:2:"24";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"12";}i:9;a:5:{s:5:"title";s:11:"ISBN Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"150";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:1:"9";}i:46;a:5:{s:5:"title";s:11:"ISSN Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"150";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"46";}i:8;a:5:{s:5:"title";s:16:"Accession Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"151";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:1:"8";}i:10;a:5:{s:5:"title";s:11:"Call Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"152";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"10";}i:11;a:5:{s:5:"title";s:13:"Other Numbers";s:4:"hint";s:0:"";s:6:"weight";s:3:"153";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"11";}i:24;a:5:{s:5:"title";s:8:"Keywords";s:4:"hint";s:0:"";s:6:"weight";s:3:"154";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:12:"autocomplete";s:12:"autocomplete";s:8:"required";i:0;}s:5:"ftdid";s:2:"24";}i:23;a:5:{s:5:"title";s:15:"French Abstract";s:4:"hint";s:0:"";s:6:"weight";s:3:"156";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"23";}i:27;a:5:{s:5:"title";s:5:"Notes";s:4:"hint";s:0:"";s:6:"weight";s:3:"157";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"27";}i:26;a:5:{s:5:"title";s:3:"URL";s:4:"hint";s:0:"";s:6:"weight";s:3:"158";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"26";}i:47;a:5:{s:5:"title";s:3:"DOI";s:4:"hint";s:0:"";s:6:"weight";s:3:"159";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"47";}i:29;a:5:{s:5:"title";s:13:"Reseach Notes";s:4:"hint";s:0:"";s:6:"weight";s:3:"160";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"29";}i:30;a:5:{s:5:"title";s:8:"Custom 1";s:4:"hint";s:0:"";s:6:"weight";s:3:"161";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"30";}i:31;a:5:{s:5:"title";s:8:"Custom 2";s:4:"hint";s:0:"";s:6:"weight";s:3:"162";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"31";}i:32;a:5:{s:5:"title";s:8:"Custom 3";s:4:"hint";s:0:"";s:6:"weight";s:3:"163";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"32";}i:33;a:5:{s:5:"title";s:8:"Custom 4";s:4:"hint";s:0:"";s:6:"weight";s:3:"164";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"33";}i:34;a:5:{s:5:"title";s:8:"Custom 5";s:4:"hint";s:0:"";s:6:"weight";s:3:"165";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"34";}i:35;a:5:{s:5:"title";s:8:"Custom 6";s:4:"hint";s:0:"";s:6:"weight";s:3:"167";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"35";}i:36;a:5:{s:5:"title";s:8:"Custom 7";s:4:"hint";s:0:"";s:6:"weight";s:3:"168";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"36";}i:38;a:5:{s:5:"title";s:11:"Short Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"169";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"38";}i:39;a:5:{s:5:"title";s:15:"Alternate Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"170";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"39";}i:40;a:5:{s:5:"title";s:16:"Translated Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"170";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"40";}i:41;a:5:{s:5:"title";s:20:"Original Publication";s:4:"hint";s:0:"";s:6:"weight";s:3:"171";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"41";}i:42;a:5:{s:5:"title";s:15:"Reprint Edition";s:4:"hint";s:0:"";s:6:"weight";s:3:"172";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"42";}i:44;a:5:{s:5:"title";s:12:"Citation Key";s:4:"hint";s:0:"";s:6:"weight";s:3:"175";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"44";}i:49;a:5:{s:5:"title";s:20:"Remote Database Name";s:4:"hint";s:0:"";s:6:"weight";s:3:"176";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"49";}i:45;a:5:{s:5:"title";s:10:"COinS Data";s:4:"hint";s:36:"This will be automatically generated";s:6:"weight";s:3:"176";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"45";}i:50;a:5:{s:5:"title";s:24:"Remote Database Provider";s:4:"hint";s:0:"";s:6:"weight";s:3:"177";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"50";}i:51;a:5:{s:5:"title";s:5:"Label";s:4:"hint";s:0:"";s:6:"weight";s:3:"178";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"51";}i:48;a:5:{s:5:"title";s:14:"Author Address";s:4:"hint";s:0:"";s:6:"weight";s:3:"178";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"48";}i:52;a:5:{s:5:"title";s:11:"Access Date";s:4:"hint";s:0:"";s:6:"weight";s:3:"179";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:5:"ftdid";s:2:"52";}}s:2:"op";s:4:"Save";s:6:"submit";s:4:"Save";s:13:"form_build_id";s:37:"form-a8ad5d9e5246d8204cc7291b0792f9eb";s:10:"form_token";s:32:"03afb3cae48e3dcaf8d9f825e5a2f527";s:7:"form_id";s:28:"biblio_admin_types_edit_form";}s:14:"clicked_button";a:18:{s:5:"#type";s:6:"submit";s:6:"#value";s:4:"Save";s:5:"#post";a:5:{s:15:"configured_flds";a:53:{i:15;a:4:{s:5:"title";s:19:"Year of Publication";s:4:"hint";s:33:"Enter YYYY, Submitted or In Press";s:10:"checkboxes";a:2:{s:6:"common";s:6:"common";s:8:"required";s:8:"required";}s:6:"weight";s:3:"-45";}i:53;a:3:{s:5:"title";s:0:"";s:4:"hint";s:0:"";s:6:"weight";s:1:"1";}i:22;a:4:{s:5:"title";s:8:"Abstract";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:1:"1";}i:1;a:5:{s:5:"title";s:7:"Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:5:{i:0;s:1:"1";i:1;s:1:"2";i:2;s:1:"3";i:3;s:1:"4";i:4;s:1:"5";}s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";s:8:"required";s:12:"autocomplete";s:12:"autocomplete";}s:6:"weight";s:1:"2";}i:2;a:5:{s:5:"title";s:12:"Contributors";s:4:"hint";s:0:"";s:9:"auth_type";a:13:{i:0;s:2:"10";i:1;s:2:"11";i:2;s:2:"12";i:3;s:2:"13";i:4;s:2:"14";i:5;s:2:"15";i:6;s:2:"16";i:7;s:2:"17";i:8;s:2:"18";i:9;s:2:"19";i:10;s:2:"20";i:11;s:2:"21";i:12;s:2:"22";}s:10:"checkboxes";a:2:{s:6:"common";s:6:"common";s:12:"autocomplete";s:12:"autocomplete";}s:6:"weight";s:1:"3";}i:3;a:4:{s:5:"title";s:16:"Tertiary Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:1:{i:0;s:1:"3";}s:6:"weight";s:1:"3";}i:4;a:4:{s:5:"title";s:18:"Subsidiary Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:1:{i:0;s:1:"4";}s:6:"weight";s:1:"4";}i:5;a:4:{s:5:"title";s:17:"Corporate Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:1:{i:0;s:1:"5";}s:6:"weight";s:1:"5";}i:6;a:3:{s:5:"title";s:15:"Secondary Title";s:4:"hint";s:0:"";s:6:"weight";s:2:"12";}i:7;a:3:{s:5:"title";s:14:"Tertiary Title";s:4:"hint";s:0:"";s:6:"weight";s:2:"13";}i:17;a:3:{s:5:"title";s:6:"Volume";s:4:"hint";s:0:"";s:6:"weight";s:2:"14";}i:43;a:3:{s:5:"title";s:7:"Section";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";}i:37;a:3:{s:5:"title";s:17:"Number of Volumes";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";}i:28;a:3:{s:5:"title";s:5:"Issue";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";}i:16;a:3:{s:5:"title";s:7:"Edition";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";}i:18;a:3:{s:5:"title";s:6:"Number";s:4:"hint";s:0:"";s:6:"weight";s:2:"16";}i:19;a:3:{s:5:"title";s:10:"Pagination";s:4:"hint";s:0:"";s:6:"weight";s:2:"17";}i:20;a:3:{s:5:"title";s:14:"Date Published";s:4:"hint";s:9:"(mm/yyyy)";s:6:"weight";s:2:"18";}i:13;a:3:{s:5:"title";s:9:"Publisher";s:4:"hint";s:0:"";s:6:"weight";s:2:"19";}i:14;a:3:{s:5:"title";s:15:"Place Published";s:4:"hint";s:0:"";s:6:"weight";s:2:"20";}i:25;a:3:{s:5:"title";s:12:"Type of Work";s:4:"hint";s:14:"Masters Thesis";s:6:"weight";s:2:"22";}i:21;a:3:{s:5:"title";s:20:"Publication Language";s:4:"hint";s:0:"";s:6:"weight";s:2:"23";}i:12;a:3:{s:5:"title";s:25:"Other Author Affiliations";s:4:"hint";s:0:"";s:6:"weight";s:2:"24";}i:9;a:4:{s:5:"title";s:11:"ISBN Number";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"150";}i:46;a:3:{s:5:"title";s:11:"ISSN Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"150";}i:8;a:4:{s:5:"title";s:16:"Accession Number";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"151";}i:10;a:4:{s:5:"title";s:11:"Call Number";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"152";}i:11;a:4:{s:5:"title";s:13:"Other Numbers";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"153";}i:24;a:4:{s:5:"title";s:8:"Keywords";s:4:"hint";s:0:"";s:10:"checkboxes";a:2:{s:6:"common";s:6:"common";s:12:"autocomplete";s:12:"autocomplete";}s:6:"weight";s:3:"154";}i:23;a:3:{s:5:"title";s:15:"French Abstract";s:4:"hint";s:0:"";s:6:"weight";s:3:"156";}i:27;a:4:{s:5:"title";s:5:"Notes";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"157";}i:26;a:4:{s:5:"title";s:3:"URL";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"158";}i:47;a:4:{s:5:"title";s:3:"DOI";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"159";}i:29;a:3:{s:5:"title";s:13:"Reseach Notes";s:4:"hint";s:0:"";s:6:"weight";s:3:"160";}i:30;a:3:{s:5:"title";s:8:"Custom 1";s:4:"hint";s:0:"";s:6:"weight";s:3:"161";}i:31;a:3:{s:5:"title";s:8:"Custom 2";s:4:"hint";s:0:"";s:6:"weight";s:3:"162";}i:32;a:3:{s:5:"title";s:8:"Custom 3";s:4:"hint";s:0:"";s:6:"weight";s:3:"163";}i:33;a:3:{s:5:"title";s:8:"Custom 4";s:4:"hint";s:0:"";s:6:"weight";s:3:"164";}i:34;a:3:{s:5:"title";s:8:"Custom 5";s:4:"hint";s:0:"";s:6:"weight";s:3:"165";}i:35;a:3:{s:5:"title";s:8:"Custom 6";s:4:"hint";s:0:"";s:6:"weight";s:3:"167";}i:36;a:3:{s:5:"title";s:8:"Custom 7";s:4:"hint";s:0:"";s:6:"weight";s:3:"168";}i:38;a:3:{s:5:"title";s:11:"Short Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"169";}i:39;a:3:{s:5:"title";s:15:"Alternate Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"170";}i:40;a:3:{s:5:"title";s:16:"Translated Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"170";}i:41;a:3:{s:5:"title";s:20:"Original Publication";s:4:"hint";s:0:"";s:6:"weight";s:3:"171";}i:42;a:3:{s:5:"title";s:15:"Reprint Edition";s:4:"hint";s:0:"";s:6:"weight";s:3:"172";}i:44;a:3:{s:5:"title";s:12:"Citation Key";s:4:"hint";s:0:"";s:6:"weight";s:3:"175";}i:49;a:3:{s:5:"title";s:20:"Remote Database Name";s:4:"hint";s:0:"";s:6:"weight";s:3:"176";}i:45;a:3:{s:5:"title";s:10:"COinS Data";s:4:"hint";s:36:"This will be automatically generated";s:6:"weight";s:3:"176";}i:50;a:3:{s:5:"title";s:24:"Remote Database Provider";s:4:"hint";s:0:"";s:6:"weight";s:3:"177";}i:51;a:3:{s:5:"title";s:5:"Label";s:4:"hint";s:0:"";s:6:"weight";s:3:"178";}i:48;a:3:{s:5:"title";s:14:"Author Address";s:4:"hint";s:0:"";s:6:"weight";s:3:"178";}i:52;a:3:{s:5:"title";s:11:"Access Date";s:4:"hint";s:0:"";s:6:"weight";s:3:"179";}}s:2:"op";s:4:"Save";s:13:"form_build_id";s:37:"form-290964395af25fac72c94913e61d1305";s:10:"form_token";s:32:"03afb3cae48e3dcaf8d9f825e5a2f527";s:7:"form_id";s:28:"biblio_admin_types_edit_form";}s:11:"#programmed";b:0;s:5:"#tree";b:0;s:8:"#parents";a:1:{i:0;s:6:"submit";}s:14:"#array_parents";a:1:{i:0;s:6:"submit";}s:7:"#weight";d:0.0040000000000000000832667268468867405317723751068115234375;s:10:"#processed";b:0;s:12:"#description";N;s:11:"#attributes";a:0:{}s:9:"#required";b:0;s:6:"#input";b:1;s:5:"#name";s:2:"op";s:12:"#button_type";s:6:"submit";s:25:"#executes_submit_callback";b:1;s:8:"#process";a:1:{i:0;s:16:"form_expand_ahah";}s:3:"#id";s:11:"edit-submit";}s:13:"process_input";b:1;s:8:"redirect";N;}
COMMON;
   
   include_once(drupal_get_path('module','biblio')."/biblio.admin.inc");
   drupal_execute('biblio_admin_types_edit_form',unserialize(trim($s_common_string)));
   
   db_query("UPDATE `biblio_field_type` SET visible = 0 WHERE fid IN(2,3,4,5) AND visible = 1"); //Hide all the other authers
   db_query("UPDATE `biblio_field_type` SET weight = -1 WHERE fid = 22");  //Move Abstract
   db_query("UPDATE `biblio_field_type` SET required = 0 WHERE fid = 15"); //No pub date req.
}

/**
 * wysiwyg configurations
 */
function _openscholar_wysiwyg_config(){
  $settings = array(
    'default' => 1,
    'user_choose' => 0,
    'show_toggle' => 1,
    'theme' => 'advanced',
    'language' => 'en',
    'buttons' => array(
      'default' => array(
        'bold' => 1,
        'italic' => 1,
        'strikethrough' => 1,
        'bullist' => 1,
        'numlist' => 1,
        'link' => 1,
        'unlink' => 1,
        'image' => 1,
        'code' => 1,
        'cut' => 1,
        'copy' => 1,
        'paste' => 1,
        'charmap' => 1
      ),
      
      'font' => array(
        'formatselect' => 1
      ),
      'fullscreen' => array(
        'fullscreen' => 1
      ),
      'paste' => array(
        'pastetext' => 1
      ),
      'table' => array(
        'tablecontrols' => 1
      ),
      'safari' => array(
        'safari' => 1
      ),
      'drupal' => array(
        'break' => 1
      )
    ),
    
    'toolbar_loc' => 'top',
    'toolbar_align' => 'left',
    'path_loc' => 'bottom',
    'resizing' => 1,
    'verify_html' => 1,
    'preformatted' => 0,
    'convert_fonts_to_spans' => 1,
    'remove_linebreaks' => 1,
    'apply_source_formatting' => 0,
    'paste_auto_cleanup_on_paste' => 1,
    'block_formats' => 'p,address,pre,h2,h3,h4,h5,h6',
    'css_setting' => 'theme',
    'css_path' => '',
    'css_classes' => ''
  )
  ;
  
  $settings = serialize($settings);
  
  $query = "SELECT format FROM {filter_formats} WHERE name='%s'";
  $filter_name = db_result(db_query($query, 'Filtered HTML'));
  $query = "INSERT INTO {wysiwyg} (format, editor, settings) VALUES ('%d', '%s', '%s')";
  db_query($query, $filter_name, 'tinymce', $settings);
}

/**
 *  Creates roles and permissions
 */
function _openscholar_create_roles(){
  install_add_role('scholar admin');
  install_add_role('scholar user');
}

/**
 * Form definition for OS flavors
 */
function _openscholar_flavors_form($form_state, $url){
  
  $form = array();
  
  $form['#action'] = $url;
  $form['#redirect'] = FALSE;
  
  $form['flavor'] = array(
    '#tree' => TRUE,
    '#type' => 'radios',
    '#title' => t('Options'),
    '#default_value' => 0,
    '#options' => array(
      t('Scholars Personal Sites'),
      t('Project Sites'),
      t('Openscholar Development')
    ),
    '#description' => t('Chose a site type to install, each type can be customized further after install by enabling/disabling modules.')
  );
  
  $form['submit'] = array(
    '#type' => 'submit',
    '#value' => st('OK')
  );
  
  return $form;
}

/**
 * Submit handler for the flavor form
 */
function _openscholar_flavors_form_submit(&$form, &$form_state){

  $flavor = $form_state['values']['flavor'];

  switch($flavor){
    case 0:       // personal
      $flavor = 'personal';
      $modules = array('scholar', 'scholar_biocv');
      $vsite_node_type = 'vsite';  // for historical reasons
      break;
    case 1:       // project
      $flavor = 'project';
      $modules = array('scholar_project');
      $vsite_node_type = 'project';  // for historical reasons
      break;
      
    case 2:       // dev
      $flavor = 'development';
      $modules = array('devel');
      break;
  
  }

  // install extra modules for each flavor
  include_once './includes/install.inc';
  drupal_install_modules($modules);
  
  // create vsite vocabs (interest, affiliation)
  _openscholar_vsite_vocabs($vsite_node_type);
  
  variable_set('openscholar_flavor_installed', $flavor);
  variable_set('openscholar_flavor_form_executed', TRUE);
}

function _openscholar_filefield_paths_config(){

  $types = _openscholar_group_posts();
  
  $file_name = array(
    'value' => '[filefield-onlyname-original].[filefield-extension-original]',
    'tolower' => 0,
    'pathauto' => 0,
    'transliterate' => 0
  );
  
  $file_path = array(
    'value' => '[space-og-path-raw]/files',
    'tolower' => 0,
    'pathauto' => 0,
    'transliterate' => 0
  );
  
  $file_alias = array(
    'value' => '[space-og-path-raw]/files/[filefield-onlyname-original].[filefield-extension-original]',
    'tolower' => 0,
    'pathauto' => 0,
    'transliterate' => 0,
    'display' => 1,
  );
  
  
  foreach ( $types as $type ) {
    $file_alias['display'] = ($type == 'image')?0:1; //turn on display for all but image
    db_query("INSERT INTO {filefield_paths} (type, field, filename, filepath, filealias) VALUES ('%s', '%s', '%s', '%s', '%s')", $type, "upload", serialize($file_name), serialize($file_path), serialize($file_alias));
  }
  
  //set the "filefield" paths
  reset($types);
  foreach ( content_fields() as $field ) {
    if (($field['module'] == 'filefield') && in_array($field['type_name'], $types)) {
      //add settings to database if applicable
      db_query("INSERT INTO {filefield_paths} (type, field, filename, filepath) VALUES ('%s', '%s', '%s', '%s')", $field['type_name'], $field['field_name'], serialize($file_name), serialize($file_path));
    }
  }
  
}

/**
 * Get an array of 'group_posts' content types names
 */
function _openscholar_group_posts(){
  //$types = og_get_types('group_post');  // not working !
  
  // get all 'group_post' content types
  $group_types = array();
  $map = spaces_features_map('node');
  $features = spaces_features('og');
  foreach ( $map as $type => $feature ) {
    if (! empty($features[$feature])) {
      $group_types[] = $type;
    }
  }
  
  return $group_types;
}

/**
 * Create the taxonomy's that will be used by the vsite object
 * @return success
 */
function _openscholar_vsite_vocabs($vsite_node_type){
  
  install_include(array(
    'taxonomy'
  ));
  
  // Create the vsite tax for affiliation
  $vocab = array(
    'name' => 'Affiliation / Department',
    'multiple' => 1,
    'required' => 0,
    'hierarchy' => 0,
    'relations' => 0,
    'module' => 'taxonomy',
    'weight' => 0,
    'nodes' => array(
      $vsite_node_type => 1
    ),
    'tags' => false,
    'help' => t('Affiliation'),
    'description' => t("A comma-separated list of affiliation that your site may have, for ex.(Math department)")
  );
  taxonomy_save_vocabulary($vocab);
  
  $vid = db_last_insert_id('vocabulary', 'vid');
  variable_set('vsite_taxonomy_affiliation', $vid);
  
  // Create the vsite tax for intrests
  $vocab = array(
    'name' => 'Related Interests',
    'description' => t("A comma-separated list of topics that may relate to the content of your site. ex.(zoology, evolutionary biology, casual inference)"),
    'multiple' => 0,
    'required' => 0,
    'hierarchy' => 0,
    'relations' => 0,
    'module' => 'taxonomy',
    'weight' => 0,
    'nodes' => array(
      $vsite_node_type => 1
    ),
    'tags' => TRUE,
    'help' => t("A comma-separated list of topics that may relate to the content of your site. ex.(zoology, evolutionary biology, casual inference)"),
  );
  taxonomy_save_vocabulary($vocab);
  
  $vid = db_last_insert_id('vocabulary', 'vid');
  variable_set('vsite_taxonomy_interests', $vid);
}


/**
 * Reimplementation of system_theme_data(). The core function's static cache
 * is populated during install prior to active install profile awareness.
 * This workaround makes enabling themes in profiles/[profile]/themes possible.
 */
function _openscholar_system_theme_data() {

  // Find themes
  $themes = drupal_system_listing('\.info$', 'themes');
  // Find theme engines
  $engines = drupal_system_listing('\.engine$', 'themes/engines');

  $defaults = system_theme_default();

  $sub_themes = array();
  // Read info files for each theme
  foreach ($themes as $key => $theme) {
    $themes[$key]->info = drupal_parse_info_file($theme->filename) + $defaults;

    // Invoke hook_system_info_alter() to give installed modules a chance to
    // modify the data in the .info files if necessary.
    drupal_alter('system_info', $themes[$key]->info, $themes[$key]);

    if (!empty($themes[$key]->info['base theme'])) {
      $sub_themes[] = $key;
    }
    if (empty($themes[$key]->info['engine'])) {
      $filename = dirname($themes[$key]->filename) .'/'. $themes[$key]->name .'.theme';
      if (file_exists($filename)) {
        $themes[$key]->owner = $filename;
        $themes[$key]->prefix = $key;
      }
    }
    else {
      $engine = $themes[$key]->info['engine'];
      if (isset($engines[$engine])) {
        $themes[$key]->owner = $engines[$engine]->filename;
        $themes[$key]->prefix = $engines[$engine]->name;
        $themes[$key]->template = TRUE;
      }
    }

    // Give the stylesheets proper path information.
    $pathed_stylesheets = array();
    foreach ($themes[$key]->info['stylesheets'] as $media => $stylesheets) {
      foreach ($stylesheets as $stylesheet) {
        $pathed_stylesheets[$media][$stylesheet] = dirname($themes[$key]->filename) .'/'. $stylesheet;
      }
    }
    $themes[$key]->info['stylesheets'] = $pathed_stylesheets;

    // Give the scripts proper path information.
    $scripts = array();
    foreach ($themes[$key]->info['scripts'] as $script) {
      $scripts[$script] = dirname($themes[$key]->filename) .'/'. $script;
    }
    $themes[$key]->info['scripts'] = $scripts;
    // Give the screenshot proper path information.
    if (!empty($themes[$key]->info['screenshot'])) {
      $themes[$key]->info['screenshot'] = dirname($themes[$key]->filename) .'/'. $themes[$key]->info['screenshot'];
    }
  }

  // Now that we've established all our master themes, go back and fill in
  // data for subthemes.
  foreach ($sub_themes as $key) {
    $themes[$key]->base_themes = system_find_base_themes($themes, $key);
    // Don't proceed if there was a problem with the root base theme.
    if (!current($themes[$key]->base_themes)) {
      continue;
    }
    $base_key = key($themes[$key]->base_themes);
    foreach (array_keys($themes[$key]->base_themes) as $base_theme) {
      $themes[$base_theme]->sub_themes[$key] = $themes[$key]->info['name'];
    }
    // Copy the 'owner' and 'engine' over if the top level theme uses a
    // theme engine.
    if (isset($themes[$base_key]->owner)) {
      if (isset($themes[$base_key]->info['engine'])) {
        $themes[$key]->info['engine'] = $themes[$base_key]->info['engine'];
        $themes[$key]->owner = $themes[$base_key]->owner;
        $themes[$key]->prefix = $themes[$base_key]->prefix;
      }
      else {
        $themes[$key]->prefix = $key;
      }
    }
  }

  // Extract current files from database.
  system_get_files_database($themes, 'theme');
  db_query("DELETE FROM {system} WHERE type = 'theme'");
  foreach ($themes as $theme) {
    $theme->owner = !isset($theme->owner) ? '' : $theme->owner;
    db_query("INSERT INTO {system} (name, owner, info, type, filename, status, throttle, bootstrap) VALUES ('%s', '%s', '%s', '%s', '%s', %d, %d, %d)", $theme->name, $theme->owner, serialize($theme->info), 'theme', $theme->filename, isset($theme->status) ? $theme->status : 0, 0, 0);
  }
}


