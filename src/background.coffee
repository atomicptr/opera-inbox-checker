INTERVAL = 60 # seconds

setBadge = (num) ->
    chrome.browserAction.setBadgeText text: num

openUrl = (url) ->
    chrome.tabs.create url: url

feedUrl = -> "https://mail.google.com/mail/u/0/feed/atom?zx=oic" + (Date.now() * Math.random())

inboxCount = (callback) ->
    request = new XMLHttpRequest()

    request.onload = ->
        if request.status == 401 # not authorized, log in and try again
            openUrl "https://mail.google.com"
        else if request.status >= 200 and request.status < 400
            doc = request.responseXML

            nsResolver = (prefix) -> if prefix == "gmail" then "http://purl.org/atom/ns#"
            countSet = doc.evaluate "/gmail:feed/gmail:fullcount", doc, nsResolver, XPathResult.ANY_TYPE, null

            countNode = countSet.iterateNext()

            if countNode
                callback null, countNode.textContent
            else
                callback "Error could not get node???"
        else
            callback
                status: request.status

    request.onerror = (err) ->
        callback err

    request.open "GET", feedUrl(), true
    request.send()

refreshIcon = ->
    inboxCount (err, count) ->
        if not err?
            if count == "0"
                setBadge ""
            else
                setBadge count
        else
            console.error err

# on click open inbox.google.com
chrome.browserAction.onClicked.addListener ->
    chrome.tabs.query
        currentWindow: true,
        active: true,
        (tab) -> openUrl "https://inbox.google.com"

# every INTERVAL (60 by default) seconds refresh the icon
setInterval refreshIcon, INTERVAL * 1000

refreshIcon()
