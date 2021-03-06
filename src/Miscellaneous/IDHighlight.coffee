IDHighlight =
  init: ->
    return if g.VIEW not in ['index', 'thread']

    Post.callbacks.push
      name: 'Highlight by User ID'
      cb:   @node

  uniqueID: null

  node: ->
    $.on @nodes.uniqueID, 'click', IDHighlight.click @ if @nodes.uniqueID
    $.on @nodes.capcode,  'click', IDHighlight.click @ if @nodes.capcode
    IDHighlight.set @ unless @isClone

  set: (post) ->
    match = (post.info.uniqueID or post.info.capcode) is IDHighlight.uniqueID
    $[if match then 'addClass' else 'rmClass'] post.nodes.post, 'highlight'

  click: (post) -> ->
    uniqueID = post.info.uniqueID or post.info.capcode
    IDHighlight.uniqueID = if IDHighlight.uniqueID is uniqueID then null else uniqueID
    g.posts.forEach IDHighlight.set
