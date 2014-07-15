fakeremove = require '..'
should = require 'should'
mongoose = require 'mongoose'

data = [{name: 'name1', num: 1}, {name: 'name2', num: 2}, {name: 'name3', num: 3}]

db = undefined
UserSchema = undefined
User = undefined

beforeEach (done) ->
	db = mongoose.createConnection('mongodb://localhost/fakeremove-test', {})
	UserSchema = new mongoose.Schema
		name: String
		num: Number
	UserSchema.plugin fakeremove
	User = db.model 'user', UserSchema
	User.create data, done

afterEach (done) ->
	User.realremove ->
		UserSchema = undefined
		User = undefined
		db.close ->
			db = undefined
			done()

describe "Import", ->
	it "mongoose plugin", ->
		fakeremove.should.be.a.Function

describe "Without fakeremove", ->
	it "on remove", (done) ->
		UserSchema2 = new mongoose.Schema
			name: String
			num: Number
		User2 = db.model 'user2', UserSchema2
		User2.remove {}, (err) ->
			should(err).not.be.ok

			User2.create data, (err) ->
				should(err).not.be.ok
				User2.find {}, (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.be.lengthOf 3

					User2.remove (err, count) ->
						should(err).not.be.ok
						count.should.be.equal(3)
						User2.find {}, (err, users) ->
							should(err).not.be.ok
							users.should.be.a.Array
							users.should.be.lengthOf 0
							User2.find().withoutpre (err, users) ->
								should(err).not.be.ok
								users.should.be.a.Array
								users.should.be.lengthOf 0
								done()

	it "on remove document and call post 'remove'", (done) ->
		UserSchema2 = new mongoose.Schema
			name: String
			num: Number
		UserSchema2.post 'remove', (doc) ->
			doc.should.be.a.Object
			done()

		User2 = db.model 'user2', UserSchema2

		User2.create data, (err) ->
			should(err).not.be.ok

			User2.findOne {}, (err, user) ->
				should(err).not.be.ok
				should(user).be.ok
				user.remove (err) ->
					should(err).not.be.ok


describe "Fakeremove", ->
	beforeEach (done) ->
		UserSchema.plugin fakeremove
		done()

	it "on remove document", (done) ->
		User.findOne {}, (err, user) ->
			should(err).not.be.ok
			userId = user._id+""
			user.remove (err) ->
				should(err).not.be.ok
				User.find {}, (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf(2)
					ids = users.map (u) -> u._id+""
					ids.should.not.containEql(userId)

					User.find({}).withoutpre (err, users) ->
						should(err).not.be.ok
						users.should.be.a.Array
						users.should.have.lengthOf(3)
						ids = users.map (u) -> u._id+""
						ids.should.containEql(userId)
						done()

	it "on remove model", (done) ->
		User.remove {}, (err, count) ->
			should(err).not.be.ok
			count.should.be.equal(3)
			User.find {}, (err, users) ->
				should(err).not.be.ok
				users.should.be.a.Array
				users.should.have.lengthOf(0)

				User.find({}).withoutpre (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf 3
					done()

	it "on remove document and call post 'remove'", (done) ->
		UserSchema.post 'remove', (doc) ->
			doc.should.be.a.Object
			done()

		User.findOne {}, (err, user) ->
			should(err).not.be.ok
			user.remove (err) ->
				should(err).not.be.ok

	it "on remove model with query", (done) ->
		User.remove {name: 'name2'}, (err, count) ->
			should(err).not.be.ok
			count.should.be.equal(1)
			User.find {}, (err, users) ->
				should(err).not.be.ok
				users.should.be.a.Array
				users.should.have.lengthOf(2)
				users = users.map (u) -> u.name
				users.should.containEql('name1')
				users.should.containEql('name3')
				users.should.not.containEql('name2')

				User.find({}).withoutpre (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf 3
					done()

	it "on fakeremove document", (done) ->
		User.findOne {}, (err, user) ->
			should(err).not.be.ok
			userId = user._id+""
			user.fakeremove (err) ->
				should(err).not.be.ok
				User.find {}, (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf(2)
					ids = users.map (u) -> u._id+""
					ids.should.not.containEql(userId)

					User.find({}).withoutpre (err, users) ->
						should(err).not.be.ok
						users.should.be.a.Array
						users.should.have.lengthOf(3)
						ids = users.map (u) -> u._id+""
						ids.should.containEql(userId)
						done()

	it "on fakeremove model", (done) ->
		User.fakeremove {}, (err, count) ->
			should(err).not.be.ok
			count.should.be.equal(3)
			User.find {}, (err, users) ->
				should(err).not.be.ok
				users.should.be.a.Array
				users.should.have.lengthOf(0)

				User.find({}).withoutpre (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf 3
					done()

	it "on fakeremove model with query", (done) ->
		User.fakeremove {name: 'name2'}, (err, count) ->
			should(err).not.be.ok
			count.should.be.equal(1)
			User.find {}, (err, users) ->
				should(err).not.be.ok
				users.should.be.a.Array
				users.should.have.lengthOf(2)
				users = users.map (u) -> u.name
				users.should.containEql('name1')
				users.should.containEql('name3')
				users.should.not.containEql('name2')

				User.find({}).withoutpre (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf 3
					done()

	it "on realremove document", (done) ->
		User.findOne {}, (err, user) ->
			should(err).not.be.ok
			user.realremove (err) ->
				should(err).not.be.ok
				User.find({}).withoutpre (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf 2
					done()

	it "on realremove model", (done) ->
		User.realremove (err) ->
			should(err).not.be.ok
			User.find({}).withoutpre (err, users) ->
				should(err).not.be.ok
				users.should.be.a.Array
				users.should.have.lengthOf 0
				done()

	it "on realremove model with query", (done) ->
		User.realremove {name: 'name2'}, (err) ->
			should(err).not.be.ok
			User.find({}).withoutpre (err, users) ->
				should(err).not.be.ok
				users.should.be.a.Array
				users.should.have.lengthOf 2
				users = users.map (u) -> u.name
				users.should.containEql('name1')
				users.should.containEql('name3')
				users.should.not.containEql('name2')
				done()

	it "on unremove document", (done) ->
		User.findOne {}, (err, user) ->
			should(err).not.be.ok
			user.remove (err) ->
				should(err).not.be.ok
				User.find {}, (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf 2

					User.find().withoutpre (err, users) ->
						should(err).not.be.ok
						users.should.be.a.Array
						users.should.have.lengthOf 3

						user.unremove (err) ->
							should(err).not.be.ok

							User.find {}, (err, users) ->
								should(err).not.be.ok
								users.should.be.a.Array
								users.should.have.lengthOf 3
								done()


	it "on unremove model", (done) ->
		User.findOne {}, (err, user) ->
			should(err).not.be.ok
			user.remove (err) ->
				should(err).not.be.ok
				User.find {}, (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf 2

					User.find().withoutpre (err, users) ->
						should(err).not.be.ok
						users.should.be.a.Array
						users.should.have.lengthOf 3

						User.unremove (err, count) ->
							should(err).not.be.ok
							count.should.be.equal 1

							User.find {}, (err, users) ->
								should(err).not.be.ok
								users.should.be.a.Array
								users.should.have.lengthOf 3
								done()


	it "on unremove model with query", (done) ->
		User.remove (err) ->
			should(err).not.be.ok
			User.find {}, (err, users) ->
				should(err).not.be.ok
				users.should.be.a.Array
				users.should.have.lengthOf 0

				User.find().withoutpre (err, users) ->
					should(err).not.be.ok
					users.should.be.a.Array
					users.should.have.lengthOf 3

					User.unremove {name: {$ne: 'name2'}}, (err, count) ->
						should(err).not.be.ok
						count.should.be.equal 2

						User.find {}, (err, users) ->
							should(err).not.be.ok
							users.should.be.a.Array
							users.should.have.lengthOf 2
							users = users.map (u) -> u.name
							users.should.containEql('name1')
							users.should.containEql('name3')
							users.should.not.containEql('name2')
							done()