package ConfigAssistant::ConfigTypes::Asset;

use strict;
use warnings;

# The `asset` config type allows you to select an asset from the blog.
sub type_asset {
    my $app = shift;
    my ( $ctx, $field_id, $field, $value ) = @_;
    $value ||= ''; # Define $value if no saved/default.
    my $blog_id = $app->blog->id;
    my $asset_html = '';

    # The asset listing screen can be filtered to show only certain types of
    # assets, such as images.
    my $filter_class = '';
    if ( $field->{filter_class} ) {
        $filter_class = '&filter=class&filter_val=' . $field->{filter_class};
    }

    if ($value) {
        my $script_uri = $app->mt_uri;
        my $static_uri = $app->static_path;

        my $asset = MT->model('asset')->load($value);
        my $asset_id    = $asset->id;
        my $asset_label = $asset->label;
        my $asset_url   = $asset->url;

        $asset_html = <<HTML;
<div id="obj-$asset_id">
    <span class="obj-title">$asset_label</span>
    <a href="${script_uri}?__mode=view&amp;_type=asset&amp;id=$asset_id&amp;blog_id=$blog_id"
        class="edit"
        target="_blank"
        title="Edit in a new window."><img
            src="${static_uri}images/status_icons/draft.gif"
            width="9" height="9" alt="Edit" /></a>
    <a href="$asset_url"
        class="view"
        target="_blank"
        title="View in a new window."><img
            src="${static_uri}images/status_icons/view.gif"
            width="13" height="9" alt="View" /></a>
    <img class="remove"
        alt="Remove selected asset"
        title="Remove selected asset"
        src="${static_uri}images/status_icons/close.gif"
        width="9" height="9" />
</div>
HTML
    }

    my $out = <<HTML;
<div class="pkg">
    <input name="$field_id" id="$field_id" class="hidden" type="hidden" value="$value" />

    <button
        type="submit"
        onclick="openDialog(null,'list_assets','_type=asset&edit_field=$field_id&blog_id=$blog_id&dialog_view=1&asset_select=1$filter_class');return false;">
        Choose asset
    </button>

    <div id="preview_${field_id}" class="asset-object">
        $asset_html
    </div>
</div>
HTML

    return $out;
}

# The normal asset insert dialog works to insert into the entry Body field,
# but we want to override this to insert into the Theme Options Asset config
# type, and use the insertSelectedAsset javascript.
sub asset_insert_param {
    my ($cb, $app, $param, $tmpl) = @_;
    my $plugin = $cb->plugin;

    my $field_id = $param->{edit_field};
    my $ts       = $app->blog->template_set;

    # The field ID is a combination of the field basename (defined in YAML) and
    # the template set ID. Strip off the template set ID (and the following
    # underscore) so that the field can be looked up.
    my $field_basename = $field_id;
    $field_basename =~ s/$ts\_//;

    # Give up if this isn't a Theme Option field. (Because the asset inserter
    # is being overridden we're affecting a widely-used screen.)
    return 1 unless $field_id
        && $ts
        && $app->registry('template_sets', $ts, 'options', $field_basename);

    my $ctx   = $tmpl->context;
    my $asset = $ctx->stash('asset');

    my $html;
    # If this asset has a URL and file path then link it for easy previewing.
    if ($asset->url && $asset->file_path) {
        $html = '<a href="<mt:AssetURL>" target="_blank"><mt:AssetLabel encode_js="1"></a>';
    }
    else {
        $html = '<mt:AssetLabel encode_js="1">';
    }

    $param->{obj_title}     = $asset->label;
    $param->{obj_id}        = $asset->id;
    $param->{obj_permalink} = $asset->url || '';
    $param->{obj_blog_id}   = $app->blog->id;

    my $new_tmpl = $plugin->load_tmpl('asset_insert.mtml', $param);

    # Use the new template.
    $tmpl->text($new_tmpl->text());
}

1;
