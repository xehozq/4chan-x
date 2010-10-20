#todo: remove close()?, make hiddenReplies/hiddenThreads local, comments, gc
#todo: remove stupid 'obj', arr el, make hidden an object, smarter xhr, text(), @this, images, clear hidden
#todo: watch - add board in updateWatcher?, redundant move divs?, redo css / hiding, manual clear
#todo: hotkeys? navlink at top?
#thread watching doesn't work in opera?

config =
    'Thread Hiding':        true
    'Reply Hiding':         true
    'Show Stubs':           true
    'Thread Navigation':    true
    'Reply Navigation':     true
    'Thread Watcher':       true
    'Thread Expansion':     true
    'Comment Expansion':    true
    'Quick Reply':          true
    'Persistent QR':        false
    'Quick Report':         true
    'Auto Watch':           true
    'Anonymize':            false

#TODO - add 'hidden' configs

AEOS =
    init: ->
        #x-browser
        if typeof GM_deleteValue == 'undefined'
            this.GM_setValue = (name, value) ->
                value = (typeof value)[0] + value
                localStorage.setItem name, value
            this.GM_getValue = (name, defaultValue) ->
                if not value = localStorage.getItem name
                    return defaultValue
                type = value[0]
                value = value.substring(1)
                switch type
                    when 'b'
                        return value == 'true'
                    when 'n'
                        return Number value
                    else
                        return value
            this.GM_addStyle = (css) ->
                style = document.createElement 'style'
                style.type = 'text/css'
                style.textContent = css
                $('head', document).appendChild(style)

        #dialog styling
        GM_addStyle '
            div.dialog {
                border: 1px solid;
                text-align: right;
            }
            div.dialog > div.move {
                cursor: move;
            }
        '

    #dialog creation
    makeDialog: (id, position) ->
        dialog = document.createElement 'div'
        dialog.id = id
        dialog.className = 'reply dialog'

        switch position
            when 'topleft'
                left = '0px'
                top = '0px'
            when 'topright'
                left = null
                top = '0px'
            when 'bottomleft'
                left = '0px'
                top = null
            when 'bottomright'
                left = null
                top = null

        left = GM_getValue "#{id}Left", left
        top  = GM_getValue "#{id}Top", top
        if left then dialog.style.left = left else dialog.style.right = '0px'
        if top then dialog.style.top = top else dialog.style.bottom = '0px'

        dialog

    #movement
    move: (e) ->
        div = @parentNode
        AEOS.div = div
        #distance from pointer to div edge is constant; calculate it here.
        AEOS.dx = e.clientX - div.offsetLeft
        AEOS.dy = e.clientY - div.offsetTop
        #factor out div from document dimensions
        AEOS.width  = document.body.clientWidth  - div.offsetWidth
        AEOS.height = document.body.clientHeight - div.offsetHeight

        document.addEventListener 'mousemove', AEOS.moveMove, true
        document.addEventListener 'mouseup',   AEOS.moveEnd, true

    moveMove: (e) ->
        div = AEOS.div

        left = e.clientX - AEOS.dx
        if left < 20 then left = '0px'
        else if AEOS.width - left < 20 then left = ''
        right = if left then '' else '0px'
        div.style.left  = left
        div.style.right = right

        top = e.clientY - AEOS.dy
        if top < 20 then top = '0px'
        else if AEOS.height - top < 20 then top = ''
        bottom = if top then '' else '0px'
        div.style.top    = top
        div.style.bottom = bottom

    moveEnd: ->
        document.removeEventListener 'mousemove', AEOS.moveMove, true
        document.removeEventListener 'mouseup',   AEOS.moveEnd, true

        div = AEOS.div
        id = div.id
        GM_setValue "#{id}Left", div.style.left
        GM_setValue "#{id}Top",  div.style.top

d = document
#utility funks
$ = (selector, root) ->
    root or= d.body
    root.querySelector(selector)
$$ = (selector, root) ->
    root or= d.body
    result = root.querySelectorAll(selector)
    #magic that turns the results object into an array:
    node for node in result
addTo = (parent, children...) ->
    for child in children
      parent.appendChild child
getConfig = (name) ->
    GM_getValue(name, config[name])
getTime = ->
    Math.floor(new Date().getTime() / 1000)
hide = (el) ->
    el.style.display = 'none'
inAfter = (root, el) ->
    root.parentNode.insertBefore(el, root.nextSibling)
inBefore = (root, el) ->
    root.parentNode.insertBefore(el, root)
n = (tag, props) -> #new
    el = d.createElement tag
    if props
        if l = props.listener
            delete props.listener
            [event, funk] = l
            el.addEventListener event, funk, true
        (el[key] = val) for key, val of props
    el
position = (el) ->
    id = el.id
    if left = GM_getValue("#{id}Left", '0px')
        el.style.left = left
    else
        el.style.right = '0px'
    if top = GM_getValue("#{id}Top", '0px')
        el.style.top = top
    else
        el.style.bottom = '0px'
remove = (el) ->
    el.parentNode.removeChild(el)
replace = (root, el) ->
    root.parentNode.replaceChild(el, root)
show = (el) ->
    el.style.display = ''
slice = (arr, id) ->
    # the while loop is the only low-level loop left in coffeescript.
    # we need to use it to see the index.
    # would it be better to just use objects and the `delete` keyword?
    i = 0
    l = arr.length
    while (i < l)
        if id == arr[i].id
            arr.splice(i, 1)
            return arr
        i++
tn = (s) ->
    d.createTextNode s
x = (path, root) ->
    root or= d.body
    d.
        evaluate(path, root, null, XPathResult.ANY_UNORDERED_NODE_TYPE, null).
        singleNodeValue

#let's get this party started.
watched = JSON.parse(GM_getValue('watched', '{}'))
if location.hostname.split('.')[0] is 'sys'
    if b = $('table font b')
        GM_setValue('error', b.firstChild.textContent)
    else
        GM_setValue('error', '')
        if getConfig('Auto Watch')
            html = $('b').innerHTML
            [nop, thread, id] = html.match(/<!-- thread:(\d+),no:(\d+) -->/)
            if thread is '0'
                board = $('meta', d).content.match(/4chan.org\/(\w+)\//)[1]
                watched[board] or= []
                watched[board].push({
                    id: id,
                    text: GM_getValue('autoText')
                })
                GM_setValue('watched', JSON.stringify(watched))
    return

[nop, BOARD, magic] = location.pathname.split('/')
if magic is 'res'
    REPLY = magic
else
    PAGENUM = parseInt(magic) || 0
xhrs = []
r = null
iframeLoop = false
callbacks = []
#godammit moot
head = $('head', d)
if not favicon = $('link[rel="shortcut icon"]', head)#/f/
    favicon = n 'link', {
        rel: 'shortcut icon'
        href: 'http://static.4chan.org/image/favicon.ico'
    }
    addTo head, favicon
favNormal = favicon.href
favEmpty = 'data:image/gif;base64,R0lGODlhEAAQAJEAAAAAAP///9vb2////yH5BAEAAAMALAAAAAAQABAAAAIvnI+pq+D9DBAUoFkPFnbs7lFZKIJOJJ3MyraoB14jFpOcVMpzrnF3OKlZYsMWowAAOw=='

hiddenThreads = JSON.parse(GM_getValue("hiddenThreads/#{BOARD}/", '[]'))
hiddenReplies = JSON.parse(GM_getValue("hiddenReplies/#{BOARD}/", '[]'))

lastChecked = GM_getValue('lastChecked', 0)
now = getTime()
DAY = 24 * 60 * 60
if lastChecked < now - 1*DAY
    cutoff = now - 7*DAY
    while hiddenThreads.length
        if hiddenThreads[0].timestamp > cutoff
            break
        hiddenThreads.shift()

    while hiddenReplies.length
        if hiddenReplies[0].timestamp > cutoff
            break
        hiddenReplies.shift()

    GM_setValue("hiddenThreads/#{BOARD}/", JSON.stringify(hiddenThreads))
    GM_setValue("hiddenReplies/#{BOARD}/", JSON.stringify(hiddenReplies))
    GM_setValue('lastChecked', now)

GM_addStyle('
    #watcher {
        position: absolute;
        border: 1px solid;
    }
    #watcher div.move {
        text-decoration: underline;
        padding: 5px 5px 0 5px;
    }
    #watcher div:last-child {
        padding: 0 5px 5px 5px;
    }
    span.error {
        color: red;
    }
    #qr.auto:not(:hover) form {
        visibility: collapse;
    }
    #qr span.error {
        position: absolute;
        bottom: 0;
        left: 0;
    }
    #qr {
        position: fixed;
        border: 1px solid;
    }
    #qr > div {
        text-align: right;
    }
    #qr > form > div {/* ad */
        display: none;
    }
    #qr td.rules {
        display: none;
    }
    #options {
        position: fixed;
        border: 1px solid;
        padding: 5px;
        text-align: right;
    }
    span.navlinks {
        position: absolute;
        right: 5px;
    }
    span.navlinks > a {
        font-size: 16px;
        text-decoration: none;
    }
    .move {
        cursor: move;
    }
    .pointer, #options label, #options a {
        cursor: pointer;
    }
')


clearHidden = ->
    #'hidden' might be misleading; it's the number of IDs we're *looking* for,
    # not the number of posts actually hidden on the page.
    GM_deleteValue("hiddenReplies/#{BOARD}/")
    GM_deleteValue("hiddenThreads/#{BOARD}/")
    @value = "hidden: 0"
    hiddenReplies = []
    hiddenThreads = []


options = ->
    #redo this
    if div = $('#options')
        remove(div)
    else
        hiddenNum = hiddenReplies.length + hiddenThreads.length
        div = n 'div', {
            id: 'options'
            className: 'reply'
        }
        position(div)
        html = '<div class="move">4chan X</div><div>'
        for option of config
            checked = if getConfig(option) then "checked" else ""
            html += "<label>#{option}<input #{checked} name=\"#{option}\" type=\"checkbox\"></label><br>"
        html += "<input type=\"button\" value=\"hidden: #{hiddenNum}\"><br>"
        html += '<a name="save">save</a> <a name="cancel">cancel</a></div>'
        div.innerHTML = html
        $('div', div).addEventListener('mousedown', AEOS.move, true)
        $('input[type="button"]', div).addEventListener('click', clearHidden, true)
        $('a[name="save"]', div).addEventListener('click', optionsSave, true)
        $('a[name="cancel"]', div).addEventListener('click', close, true)
        addTo d.body, div


showThread = ->
    div = this.nextSibling
    show(div)
    hide(this)
    id = div.id
    slice(hiddenThreads, id)
    GM_setValue("hiddenThreads/#{BOARD}/", JSON.stringify(hiddenThreads))


hideThread = (div) ->
    if p = this.parentNode
        div = p
        hiddenThreads.push({
            id: div.id
            timestamp: getTime()
        })
        GM_setValue("hiddenThreads/#{BOARD}/", JSON.stringify(hiddenThreads))
    hide(div)
    if getConfig('Show Stubs')
        if span = $('.omittedposts', div)
            num = Number(span.textContent.match(/\d+/)[0])
        else
            num = 0
        num += $$('table', div).length
        text = if num is 1 then "1 reply" else "#{num} replies"
        name = $('span.postername', div).textContent
        trip = $('span.postername + span.postertrip', div)?.textContent || ''
        a = n 'a', {
            textContent: "[ + ] #{name}#{trip} (#{text})"
            className: 'pointer'
            listener: ['click', showThread]
        }
        inBefore(div, a)


threadF = (current) ->
    div = n 'div', {
        className: 'thread'
    }
    a = n 'a', {
        textContent: '[ - ]'
        className: 'pointer'
        listener: ['click', hideThread]
    }
    addTo div, a

    inBefore(current, div)
    while (!current.clear)#<br clear>
        addTo div, current
        current = div.nextSibling
    addTo div, current
    current = div.nextSibling

    id = $('input[value="delete"]', div).name
    div.id = id
    #check if we should hide the thread
    for hidden in hiddenThreads
        if id == hidden.id
            hideThread(div)

    current = current.nextSibling.nextSibling
    if current.nodeName isnt 'CENTER'
        threadF(current)


showReply = ->
    div = this.parentNode
    table = div.nextSibling
    show(table)
    remove(div)
    id = $('td.reply, td.replyhl', table).id
    slice(hiddenReplies, id)
    GM_setValue("hiddenReplies/#{BOARD}/", JSON.stringify(hiddenReplies))


hideReply = (reply) ->
    if p = this.parentNode
        reply = p.nextSibling
        hiddenReplies.push({
            id: reply.id
            timestamp: getTime()
        })
        GM_setValue("hiddenReplies/#{BOARD}/", JSON.stringify(hiddenReplies))

    name = $('span.commentpostername', reply).textContent
    trip = $('span.postertrip', reply)?.textContent || ''
    table = x('ancestor::table', reply)
    hide(table)
    if getConfig('Show Stubs')
        a = n 'a', {
            textContent: "[ + ] #{name} #{trip}"
            className: 'pointer'
            listener: ['click', showReply]
        }
        div = n 'div'
        addTo div, a
        inBefore(table, div)


optionsSave = ->
    div = this.parentNode.parentNode
    inputs = $$('input', div)
    for input in inputs
        GM_setValue(input.name, input.checked)
    remove(div)


close = ->
    div = this.parentNode.parentNode
    remove(div)


iframeLoad = ->
    if iframeLoop = !iframeLoop
        return
    $('iframe').src = 'about:blank'

    qr = $('#qr')
    if error = GM_getValue('error')
        $('form', qr).style.visibility = ''
        span = n 'span', {
            textContent: error
            className: 'error'
        }
        addTo qr, span
    else if REPLY and getConfig('Persistent QR')
        $('textarea', qr).value = ''
        $('input[name=recaptcha_response_field]', qr).value = ''
    else
        remove qr

    window.location = 'javascript:Recaptcha.reload()'


submit = (e) ->
    if span = @nextSibling
        remove(span)
    recaptcha = $('input[name=recaptcha_response_field]', this)
    if recaptcha.value
        $('#qr input[title=autohide]:not(:checked)')?.click()
    else
        e.preventDefault()
        span = n 'span', {
            className: 'error'
            textContent: 'You forgot to type in the verification.'
        }
        addTo @parentNode, span
        alert 'You forgot to type in the verification.'
        recaptcha.focus()


autohide = ->
    qr = $ '#qr'
    klass = qr.className
    if klass.indexOf('auto') is -1
        klass += ' auto'
    else
        klass = klass.replace(' auto', '')
    qr.className = klass


quickReply = (e) ->
    unless qr = $('#qr')
        #make quick reply dialog
        qr = n 'div', {
            id: 'qr'
            className: 'reply'
        }
        position(qr)

        div = n 'div', {
            innerHTML: 'Quick Reply '
            className: 'move'
            listener: ['mousedown', AEOS.move]
        }
        addTo qr, div

        autohideB = n 'input', {
            type: 'checkbox'
            className: 'pointer'
            title: 'autohide'
            listener: ['click', autohide]
        }
        closeB = n 'a', {
            textContent: 'X'
            className: 'pointer'
            title: 'close'
            listener: ['click', close]
        }
        addTo div, autohideB, tn(' '), closeB

        form = $ 'form[name=post]'
        clone = form.cloneNode(true)
        #remove recaptcha scripts
        for script in $$ 'script', clone
            remove script
        clone.addEventListener('submit', submit, true)
        clone.target = 'iframe'
        if not REPLY
            xpath = 'preceding::span[@class="postername"][1]/preceding::input[1]'
            input = n 'input', {
                type: 'hidden'
                name: 'resto'
                value: x(xpath, this).name
            }
            addTo clone, input
        addTo qr, clone
        addTo d.body, qr

    if e
        e.preventDefault()

        $('input[title=autohide]:checked', qr)?.click()

        selection = window.getSelection()
        id = x('preceding::span[@id][1]', selection.anchorNode)?.id
        text = selection.toString()

        textarea = $('textarea', qr)
        textarea.focus()
        #we can't just use @textContent b/c of the xxxs. goddamit moot.
        textarea.value += '>>' + @parentNode.id.match(/\d+$/)[0] + '\n'
        if text and id is this.parentNode.id
            textarea.value += ">#{text}\n"

watch = ->
    id = this.nextSibling.name
    if this.src[0] is 'd'#data:png
        this.src = favNormal
        text = "/#{BOARD}/ - " +
            x('following-sibling::blockquote', this).textContent.slice(0,25)
        watched[BOARD] or= []
        watched[BOARD].push({
            id: id,
            text: text
        })
    else
        this.src = favEmpty
        watched[BOARD] = slice(watched[BOARD], id)

    GM_setValue('watched', JSON.stringify(watched))
    watcherUpdate()


watchX = ->
    [board, nop, id] =
        this.nextElementSibling.getAttribute('href').substring(1).split('/')
    watched[board] = slice(watched[board], id)
    GM_setValue('watched', JSON.stringify(watched))
    watcherUpdate()
    if input = $("input[name=\"#{id}\"]")
        favicon = input.previousSibling
        favicon.src = favEmpty


watcherUpdate = ->
    div = n 'div'
    for board of watched
        for thread in watched[board]
            a = n 'a', {
                textContent: 'X'
                className: 'pointer'
                listener: ['click', watchX]
            }
            link = n 'a', {
                textContent: thread.text
                href: "/#{board}/res/#{thread.id}"
            }
            addTo div, a, tn(' '), link, n('br')
    old = $('#watcher div:last-child')
    replace(old, div)


parseResponse = (responseText) ->
    body = n 'body', {
        innerHTML: responseText
    }
    replies = $$('td.reply', body)
    opbq = $('blockquote', body)
    return [replies, opbq]


onloadThread = (responseText, span) ->
    [replies, opbq] = parseResponse(responseText)
    span.textContent = span.textContent.replace('X Loading...', '- ')

    #make sure all comments are fully expanded
    span.previousSibling.innerHTML = opbq.innerHTML
    while (next = span.nextSibling) and not next.clear#<br clear>
        remove(next)
    if next
        for reply in replies
            inBefore(next, x('ancestor::table', reply))
    else#threading
        div = span.parentNode
        for reply in replies
            addTo div, x('ancestor::table', reply)


expandThread = ->
    id = x('preceding-sibling::input[1]', this).name
    span = this

    #close expanded thread
    if span.textContent[0] is '-'
        #goddamit moot
        num = if board is 'b' then 3 else 5
        table = x("following::br[@clear][1]/preceding::table[#{num}]", span)
        while (prev = table.previousSibling) and (prev.nodeName is 'TABLE')
            remove(prev)
        span.textContent = span.textContent.replace('-', '+')
        return

    span.textContent = span.textContent.replace('+', 'X Loading...')
    #load cache
    for xhr in xhrs
        if xhr.id == id
            #why can't we just xhr.r.onload()?
            onloadThread(xhr.r.responseText, span)
            return

    #create new request
    r = new XMLHttpRequest()
    r.onload = ->
        onloadThread(this.responseText, span)
    r.open('GET', "res/#{id}", true)
    r.send()
    xhrs.push({
        r: r,
        id: id
    })


onloadComment = (responseText, a, href) ->
    [nop, op, id] = href.match(/(\d+)#(\d+)/)
    [replies, opbq] = parseResponse(responseText)
    if id is op
        html = opbq.innerHTML
    else
        #css selectors don't like ids starting with numbers,
        # getElementById only works for root document.
        for reply in replies
            if reply.id == id
                html = $('blockquote', reply).innerHTML
    bq = x('ancestor::blockquote', a)
    bq.innerHTML = html


expandComment = (e) ->
    e.preventDefault()
    a = this
    href = a.getAttribute('href')
    r = new XMLHttpRequest()
    r.onload = ->
        onloadComment(this.responseText, a, href)
    r.open('GET', href, true)
    r.send()
    xhrs.push({
        r: r,
        id: href.match(/\d+/)[0]
    })


report = ->
    input = x('preceding-sibling::input[1]', this)
    input.click()
    $('input[value="Report"]').click()
    input.click()


nodeInserted = (e) ->
    target = e.target
    if target.nodeName is 'TABLE'
        for callback in callbacks
            callback(target)
    else if target.id is 'recaptcha_challenge_field' and qr = $ '#qr'
        $('#recaptcha_image img', qr).src = "http://www.google.com/recaptcha/api/image?c=" + target.value
        $('#recaptcha_challenge_field', qr).value = target.value


autoWatch = ->
    autoText = $('textarea', this).value.slice(0, 25)
    GM_setValue('autoText', "/#{BOARD}/ - #{autoText}")


stopPropagation = (e) ->
    e.stopPropagation()


replyNav = ->
    if REPLY
        window.location = if @textContent is '▲' then '#navtop' else '#navbot'
    else
        direction = if @textContent is '▲' then 'preceding' else 'following'
        op = x("#{direction}::span[starts-with(@id, 'nothread')][1]", this).id
        window.location = "##{op}"


#graceful exit
unless navtopr = $ '#navtopr a'
    return
text = navtopr.nextSibling
a = n 'a', {
    textContent: 'X'
    className: 'pointer'
    listener: ['click', options]
}
inBefore(text, tn(' / '))
inBefore(text, a)

#hack to tab from comment straight to recaptcha
for el in $$ '#recaptcha_table a'
    el.tabIndex = 1

if getConfig('Reply Hiding')
    callbacks.push((root) ->
        tds = $$('td.doubledash', root)
        for td in tds
            a = n 'a', {
                textContent: '[ - ]'
                className: 'pointer'
                listener: ['click', hideReply]
            }
            replace(td.firstChild, a)

            next = td.nextSibling
            id = next.id
            for obj in hiddenReplies
                if obj.id is id
                    hideReply(next)
    )

if getConfig('Quick Reply')
    iframe = n 'iframe', {
        name: 'iframe'
        listener: ['load', iframeLoad]
    }
    hide(iframe)
    addTo d.body, iframe

    callbacks.push((root) ->
        quotes = $$('a.quotejs:not(:first-child)', root)
        for quote in quotes
            quote.addEventListener('click', quickReply, true)
    )

    #hack - nuke id so it doesn't grab focus when reloading
    $('#recaptcha_response_field').id = ''


if getConfig('Quick Report')
    callbacks.push((root) ->
        arr = $$('span[id^=no]', root)
        for el in arr
            a = n 'a', {
                textContent: '[ ! ]'
                className: 'pointer'
                listener: ['click', report]
            }
            inAfter(el, a)
            inAfter(el, tn(' '))
    )

if getConfig('Thread Watcher')
    #create watcher
    watcher = n 'div', {
        innerHTML: '<div class="move">Thread Watcher</div><div></div>'
        className: 'reply'
        id: 'watcher'
    }
    position(watcher)
    $('div', watcher).addEventListener('mousedown', AEOS.move, true)
    addTo d.body, watcher
    watcherUpdate()

    #add buttons
    threads = watched[BOARD] || []
    #normal, threading
    inputs = $$('form > input[value="delete"], div > input[value="delete"]')
    for input in inputs
        id = input.name
        for thread in threads
            if id == thread.id
                src = favNormal
                break
        src or= favEmpty
        img = n 'img', {
            src: src
            className: 'pointer'
            listener: ['click', watch]
        }
        inBefore(input, img)

if getConfig('Anonymize')
    callbacks.push((root) ->
        names = $$('span.postername, span.commentpostername', root)
        for name in names
            name.innerHTML = 'Anonymous'
        trips = $$('span.postertrip', root)
        for trip in trips
            if trip.parentNode.nodeName is 'A'
                remove(trip.parentNode)
            else
                remove(trip)
    )

if getConfig('Reply Navigation')
    callbacks.push((root) ->
        arr = $$('span[id^=norep]', root)
        for el in arr
            span = n 'span'
            up = n 'a', {
                textContent: '▲'
                className: 'pointer'
                listener: ['click', replyNav]
            }
            down = n 'a', {
                textContent: '▼'
                className: 'pointer'
                listener: ['click', replyNav]
            }
            addTo span, tn(' '), up, tn(' '), down
            inAfter(el, span)
    )

if REPLY
    if getConfig('Quick Reply') and getConfig('Persistent QR')
        quickReply()
        $('#qr input[title=autohide]').click()

else # not reply
    if getConfig('Thread Hiding')
        delform = $('form[name=delform]')
        #don't confuse other scripts
        d.addEventListener('DOMNodeInserted', stopPropagation, true)
        threadF(delform.firstChild)
        d.removeEventListener('DOMNodeInserted', stopPropagation, true)

    if getConfig('Auto Watch')
        $('form[name="post"]').addEventListener('submit', autoWatch, true)

    if getConfig('Thread Navigation')
        arr = $$('div > span.filesize, form > span.filesize')
        i = 0
        l = arr.length
        l1 = l + 1
        #should this be a while loop?
        for el in arr
            if i isnt 0
                textContent = '▲'
                href = "##{i}"
            else if PAGENUM isnt 0
                textContent = '◀'
                href = "#{PAGENUM - 1}"
            else
                textContent = '▲'
                href = "#navtop"

            up = n 'a', {
                className: 'pointer'
                textContent: textContent
                href: href
            }

            span = n 'span', {
                className: 'navlinks'
                id: ++i
            }
            i1 = i + 1
            down = n 'a', {
                className: 'pointer'
            }
            if i1 == l1
                down.textContent = '▶'
                down.href = "#{PAGENUM + 1}#1"
            else
                down.textContent = '▼'
                down.href = "##{i1}"

            addTo span, up, tn(' '), down
            inBefore el, span
        if location.hash is '#1'
            window.location = window.location

    if getConfig('Thread Expansion')
        omitted = $$('span.omittedposts')
        for span in omitted
            a = n 'a', {
                className: 'pointer omittedposts'
                textContent: "+ #{span.textContent}"
                listener: ['click', expandThread]
            }
            replace(span, a)

    if getConfig('Comment Expansion')
        as = $$('span.abbr a')
        for a in as
            a.addEventListener('click', expandComment, true)

for callback in callbacks
    callback()
d.body.addEventListener('DOMNodeInserted', nodeInserted, true)
