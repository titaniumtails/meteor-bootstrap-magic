#i18n snub
UI.registerHelper "__", (keyName) -> 
  return keyName

reactive =
  overrides : new ReactiveDict
  defaults : new ReactiveDict

@BootstrapMagic =
  on : (eventName, callback) ->
    @[eventName] = callback

  off : (eventName) ->
    delete @[eventName]

  setOne: (dictionary, key, val) ->
    reactive[dictionary].set key, val
    obj = {}
    obj[key] = val
    @change obj if @change

  setMany: (dictionary, obj) ->
    for key,val of obj
      reactive[dictionary].set key, val

  dictionary: reactive

  setOverride : (key, val) -> @setOne 'overrides', key, val
  setOverrides : (obj) -> @setMany 'overrides', obj
  setDefault : (key, val) -> @setOne 'defaults', key, val
  setDefaults : (obj) -> @setMany 'defaults', obj

 # why not make this scoped to the template?
UI.registerHelper 'BootstrapMagicOverride', ->
  reactive.overrides.get(@key) || reactive.defaults.get(@key)

#Something for Everyone
format = (str, del) -> str.replace(/\s+/g, del || '-').toLowerCase()
formatCamel = (str) -> 
  str = str.replace(/([^A-Za-z0-9\.\$])|([A-Z])(?=[A-Z][a-z])|([^\-\$\.0-9])(?=\$?[0-9]+(?:\.[0-9]+)?)|([0-9])(?=[^\.0-9])|([a-z])(?=[A-Z])/g, '$2$3$4$5 ')
  str.charAt(0).toUpperCase() + str.slice(1)
camelToSnake = (str) -> str.replace(/\W+/g, '_').replace(/([a-z\d])([A-Z])/g, '$1-$2')

@currentPage = new ReactiveVar()
@currentMenuItem = new ReactiveVar()

getCurrentSubCat = ->
  for group in bootstrap_magic_variables
    if group.keyName is currentPage.get()
      return group

initColorPicker = (node) ->

  # colorpicker's changeColor fires too often!
  $('.color-picker-group', node).colorpicker
    horizontal: true

  .on 'showPicker', ->
    @startVal = $('input', @).val()

  .on 'hidePicker', ->
    $input = $('input',@)
    @endVal = $input.val()
    if @startVal and @startVal isnt @endVal
      @startVal = @endVal
      $input.trigger 'change'


#Time for Templates

Template._bootstrap_magic.created = ->
  # trigger start event
  BootstrapMagic.start() if BootstrapMagic.start

Template._bootstrap_magic.rendered = ->
  currentMenuItem.set bootstrap_magic_variables[0].category
  currentPage.set bootstrap_magic_variables[0].keyName
  @.autorun -> 
    currentPage.get()
    currentMenuItem.get()
    Meteor.defer -> initColorPicker($('.color-picker-area'))

Template._bootstrap_magic.helpers
  
  # "groups" : ->
  #   for group in bootstrap_magic_variables
  #     for lessVar in group.data
  #       lessVar.value = reactive.defaults.keys[lessVar.key] || lessVar.value
  #   return bootstrap_magic_variables

  "categories" : ->  _.map _.groupBy(bootstrap_magic_variables, 'category'), (obj) ->  obj[0]
  "subCategories" : ->  _.map _.where(bootstrap_magic_variables, { category: currentMenuItem.get() }), (obj) -> obj
  "previewTmpl" : -> Template["bootstrap_magic_preview_#{camelToSnake @keyName}"] || null
  "inputTmpl" : -> Template["bootstrap_magic_input_#{@type}"] || null
  "formattedCat" : -> formatCamel @category
  "typeIs" : (type) -> @type is type
  "currentSubCat" : getCurrentSubCat
  "isSelectedCat" : -> @category is currentMenuItem.get()
  "isSelectedSubCat" : ->  @keyName is currentPage.get()

Template._bootstrap_magic.events
  'change input.bootstrap-magic-input' : (e) ->
    $input = $(e.currentTarget)
    BootstrapMagic.setOverride $input.attr('name'), $input.val()

  'click .menu-secondary-list' : -> 
    currentMenuItem.set(@category)
    if (_.map _.where(bootstrap_magic_variables, { category: currentMenuItem.get() }), (obj) -> obj).length is 1
      currentPage.set(_.where(bootstrap_magic_variables, { category: currentMenuItem.get() })[0].keyName)
 
  'click .menu-tertiary-list' : -> currentPage.set(@keyName)

  # 'click #reset' :-> do something