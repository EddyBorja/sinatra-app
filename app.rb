require 'sinatra'
require 'data_mapper'
require 'time'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'

SITE_TITLE = "mainloop"
SITE_DESCRIPTION = "Stay in the loop."

enable :sessions

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class Note
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :complete, Boolean, :required => true, :default => 0
	property :created_at, DateTime
	property :updated_at, DateTime
end

DataMapper.auto_upgrade!

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end


get '/' do
	@notes = Note.all :order => :id.desc
	@title = 'All Notes'
	if @notes.empty?
		flash[:error] = 'No notes found. Add your first below.'
	end 
	erb :home
end

post '/' do
	note = Note.new
	note.attributes = {
		:content => params[:content],
		:created_at => Time.now,
		:updated_at => Time.now
	}
	if note.save
		redirect '/', :notice => 'Note created successfully.'
	else
		redirect '/', :error => 'Failed to save note.'
	end
end

get '/rss.xml' do
	@notes = Note.all :order => :id.desc
	builder :rss
end

get '/:id' do
	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	if @note
		erb :edit
	else
		redirect '/', :error => "Can't find that note."
	end
end

put '/:id' do
	note = Note.get params[:id]
	unless note
		redirect '/', :error => "Can't find that note."
	end
	note.attributes = {
		:content => params[:content],
		:complete => params[:complete] ? 1 : 0,
		:updated_at => Time.now
	}
	if note.save
		redirect '/', :notice => 'Note updated successfully.'
	else
		redirect '/', :error => 'Error updating note.'
	end
end

get '/:id/delete' do
	@note = Note.get params[:id]
	@title = "Confirm deletion of note ##{params[:id]}"
	if @note
		erb :delete
	else
		redirect '/', :error => "Can't find that note."
	end
end

delete '/:id' do
	note = Note.get params[:id]
	if note.destroy
		redirect '/', :notice => 'Note deleted successfully.'
	else
		redirect '/', :error => 'Error deleting note.'
	end
end

get '/:id/complete' do
	note = Note.get params[:id]
	unless note
		redirect '/', :error => "Can't find that note."
	end
	note.attributes = {
		:complete => note.complete ? 0 : 1, # flip it
		:updated_at => Time.now
	}
	if note.save
		redirect '/', :notice => 'Note marked as complete.'
	else
		redirect '/', :error => 'Error marking note as complete.'
	end
end