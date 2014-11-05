mongoose	= require 'mongoose'
Query		= mongoose.Query
Model		= mongoose.Model
queryHook	= require 'mongoose-query-hook'

wrap = (fn, wrap) ->
	->
		wrap.apply this, [fn].concat(Array::slice.call(arguments))

isPatched = false
pathMongoose = ->
	return if isPatched
	isPatched = true
	minorVersion = +mongoose.version.split(".")[1]

	if minorVersion is 6
		Model::remove = wrap Model::remove, (origFn, callback) ->
			if not @$__._real_remove and @schema?._useFakeRemove
				@fakeremove callback
			else
				origFn.call @, callback

		Query::fakeremove = (callback) ->
			@setOptions {multi: true}
			@update {$set: {deletedAt: Date.now()}}, callback

		Query::realremove = ->
			@_real_remove = true
			@withoutpre().remove.apply @, arguments

		Query::unremove = (callback) ->
			@setOptions {multi: true}
			@withoutpre().where('deletedAt').exists(true).update {$unset: {deletedAt: 1}}, callback


		Query::remove = wrap Query::remove, (origFn, args...) ->
			if not @model?.schema?._useFakeRemove or @_real_remove
				origFn.apply @, args
			else
				@fakeremove.apply @, args



	else if minorVersion is 8
		throw new Error "mongoose 3.8 not be implemented"
		Query::remove = (cond, callback) ->
			true

module.exports = (schema, options) ->
	pathMongoose()
	return if schema._useFakeRemove is true
	schema.add {deletedAt: Date}
#	schema.path('deletedAt').index {sparse: true}
	schema.path('deletedAt').index {sparse: false}


	schema.plugin queryHook,
		preQuery: (op, next) ->
			@where("deletedAt").exists(false)
			next()

	schema._useFakeRemove = true

	schema.methods.fakeremove = (callback) ->
		@update({$set: {deletedAt: Date.now()}}).withoutpre (err) =>
			return callback.apply @, arguments if err?
			@emit 'remove', @
			callback.apply @, arguments

	schema.methods.realremove = (callback) ->
		@$__._real_remove = true
		@remove callback

	schema.methods.unremove = (callback) ->
		@update({$unset: {deletedAt: 1}}).withoutpre callback

	schema.statics.realremove = (cond, callback) ->
		if typeof cond is "function"
			[callback, cond] = [cond, {}]
		@find(cond).realremove callback

	schema.statics.fakeremove = (cond, callback) ->
		if typeof cond is "function"
			[callback, cond] = [cond, {}]
		@find(cond).fakeremove callback

	schema.statics.unremove = (cond, callback) ->
		if typeof cond is "function"
			[callback, cond] = [cond, {}]
		@find(cond).unremove callback


