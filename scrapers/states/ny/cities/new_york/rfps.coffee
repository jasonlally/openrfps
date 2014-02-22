# Require the necessary modules.
request = require 'request'
cheerio = require 'cheerio'
async = require 'async'
_ = require 'underscore'
fs = require 'fs'
require 'colors'

FORM_DATA =
  TON:1
  Alpha:true
  ProcurCat:0
  Type:'A'
  searchDescriptions:'yes'
  qryType:'all'

module.exports = (opts, done) ->

  rfps = []
  currentPage = 0

  addListing = ($, $wrapper) ->
    item = {}
    item.title = $wrapper.find('h4').text()
    item.description = $('body').text().split(item.title)[1].split('Due Date')[0]
    rfps.push(item)

  getPage = (cb) ->
    currentPage += 1

    console.log "Getting page #{currentPage}"

    startPoint = if currentPage == 1
      null
    else if currentPage == 2
      0
    else
      (currentPage - 2) * 25

    # request.post 'http://a856-internet.nyc.gov/nycvendoronline/vendorsearch/asp/Postings.asp',
    #   form: _.extend({ startPoint: startPoint}, FORM_DATA),
    # , (err, response, body) ->
    body = fs.readFileSync('./scrapers/states/ny/cities/new_york/html.html')
    console.log "Received page #{currentPage}".yellow
    $ = cheerio.load body

    $('.Hbox-blue').eq(0).each (i, _) ->
      return if $(@).text().match /Records (\d+) to/

      $newWrapper = $('<div />')
      $(@).nextUntil('.Hbox-blue').each ->
        $newWrapper.append $(@).clone()
      addListing($, $newWrapper)

    console.log "Parsed page #{currentPage}".green

    # if $('#A1').length > 0
    #   getPage(cb)
    # else
    #   cb()
    cb()

  getPage ->
    console.log 'All done!'.green
    done rfps
