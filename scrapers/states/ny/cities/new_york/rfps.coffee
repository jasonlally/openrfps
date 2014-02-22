# Require the necessary modules.
request = require 'request'
cheerio = require 'cheerio'
async = require 'async'
_ = require 'underscore'
fs = require 'fs'
require 'colors'

EMAIL_REGEX = /(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/
PHONE_REGEX = /Phone\: (\([0-9]{3}\) [0-9]{3}-[0-9]{4})/

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

  addListing = (id, $, $wrapper) ->
    item = {}
    item.title = $wrapper.find('h4').text()

    addNext = (el) ->
      return unless el?
      unless $(el.next).hasClass('Hbox-grey')
        return unless el.next?.type?
        text += (if el.next.type == 'text' then el.next.data else "\n")
        addNext(el.next)

    text = ""
    $form = $("##{id}")
    addNext($form[0])
    item.description = text

    item.id = item.description.match(/PIN\# (\S+)/)?[1] ||
              item.description.match(/RFQ\s+\#\s+((\S+)(\s+)?A?R?S?)/)[1]
    item.responses_due_at = $wrapper.find('h5:contains(Due Date)')[0]?.next.data
    item.created_at = $wrapper.find('h5:contains(Published)')[0]?.next.data
    item.department_name = $wrapper.find('h5:contains(Agency)')[0]?.next.data
    item.address = $wrapper.find('h5:contains(Address)')[0]?.next.data

    contactText = $wrapper.find('h5:contains(Contact)').parent().html()?.replace(/<br>/ig, ' ')

    if contactText
      item.contact_name = $wrapper.find('h5:contains(Contact)')[0]?.next.data
      item.contact_email = contactText.match(EMAIL_REGEX)?[0]
      item.contact_phone = contactText.match(PHONE_REGEX)?[1]

    console.log "Adding #{item.id}".green
    rfps.push(item)

  getPage = (cb) ->
    currentPage += 1

    console.log "Getting page #{currentPage}"

    moreParams = if currentPage == 1
      { }
    else if currentPage == 2
      { startPoint: 0, hdnNextAD: 'next' }
    else
      { startPoint: (currentPage - 2) * 25, hdnNextAD: 'next' }

    request.post 'http://a856-internet.nyc.gov/nycvendoronline/vendorsearch/asp/Postings.asp',
      form: _.extend(moreParams, FORM_DATA),
    , (err, response, body) ->
      console.log "Received page #{currentPage}".yellow
      $ = cheerio.load body

      $('form[target=newWindow]').each (i, _) ->
        return if $(@).text().match /Records (\d+) to/

        $newWrapper = $('<div />')
        $(@).nextUntil('.Hbox-blue').each ->
          $newWrapper.append $(@).clone()
        id = $(@).attr('id')
        return unless id
        addListing(id, $, $newWrapper)

      console.log "Parsed page #{currentPage}".green

      if $('#A1').length > 0
        getPage(cb)
      else
        cb()

  getPage ->
    console.log 'All done!'.green
    done rfps
