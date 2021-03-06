class SubjectsController < ApplicationController
	before_action :authenticate_user, :only => [:new, :create, :edit, :update, :create_message, :toggle_pinned, :start_following_subject, :stop_following_subject]
	before_action only: [:index, :show] do
		authenticate_user(false)
	end
	before_action :same_user_check, :only => [:edit, :update]
	before_action :admin_check, :only => [:toggle_pinned]
	after_action :update_last_forum_visit
	after_action :clear_unread_subjects_count, :only => [:index]
	
	def index
		# Pagination
		params[:page] ||= 1
		@subjects = Subject.order(pinned: :desc, created_at: :desc).paginate(:page => params[:page])
	end
	
	def show 
		@subject = Subject.find(params[:subject_id])
		@subject.update(views: @subject.views + 1)
		@message = ForumMessage.new
		
		# Pagination
		params[:page] ||= 1
		params[:page] = @subject.forum_messages.count.zero? ? 1 : (@subject.forum_messages.count / ForumMessage.per_page.to_f).ceil if params[:page] == 'last'
		@messages = @subject.forum_messages.order(:created_at).paginate(:page => params[:page])
	end
	
	def new
		@subject = Subject.new
		@message = ForumMessage.new
	end
	
	def create
		@subject = Subject.new(new_subject_params)
		@message = ForumMessage.new(:text => params[:text])
		
		@message.user = User.find(session[:user_id])
		@message.subject = @subject
		
		@subject.pinned = false
		@subject.views = 0
		
		@subject.valid?
		@message.valid?
		
		if @subject.errors.any? || @message.errors.any?
			(@subject.errors.full_messages + @message.errors.full_messages).each do |m|
				show_error(m)
			end
			render "new"
		else
			@subject.save
			@message.subject = @subject
			@message.save
			@subject.forum_messages << @message
			@subject.update(forum_messages: @subject.forum_messages)
			
			update_unread_subjects
			redirect_to "/subjects/#{@subject.id}"
		end
	end
	
	def edit
		@message = ForumMessage.find(params[:message_id])
		@subject = @message.subject
	end
	
	def update
		@message = ForumMessage.find(params[:message_id])
		@subject = @message.subject
		
		if @message.update(message_params)
			redirect_to "/subjects/#{@subject.id}?page=last"
		else
			@message.errors.full_messages.each do |m|
				show_error(m)
			end
			render "edit"
		end
	end
	
	def toggle_pinned
		@subject = Subject.find(params[:subject_id])
		@subject.update(pinned: !@subject.pinned)
		redirect_to "/subjects/#{params[:subject_id]}"
	end
	
	def create_message
		@subject = Subject.find(params[:subject_id])
		@message = ForumMessage.new(message_params)
		
		@message.user_id = session[:user_id]
		@message.subject = @subject
		
		if @message.valid?
			@message.save
			@subject.update(forum_messages: (@subject.forum_messages << @message))
			
			update_unread_subjects
			# Send mail to followers
			@subject.following_users.each do |u|
				if u != @current_user
					Pony.mail(:to => u.email, :subject => "BeOI-Training: New message in followed subject \"#{@subject.title}\"", :html_body => "Hello #{u.display_name},<br><br>#{@current_user.display_name} posted a new message in a subject that you follow, #{view_context.link_to @subject.title, "#{ENV['APP_URL']}/subjects/#{@subject.id}"}. You can read that message #{view_context.link_to "here", "#{ENV['APP_URL']}/subjects/#{@subject.id}"}.<br><br>If you don't want to follow this subject anymore, please click on #{view_context.link_to "this link", "#{ENV['APP_URL']}/subjects/#{@subject.id}", method: :delete}.<br><br>Yours truly,<br>The BeOI Training team.")
				end
			end
			redirect_to "/subjects/#{@subject.id}?page=last"
		else
			@message.errors.full_messages.each do |m|
				show_error(m)
			end
			render "show", subject_id: params[:subject_id]
		end
	end
	
	def start_following_subject
		@subject = Subject.find(params[:subject_id])
		if !@subject.following_users.exists?(@current_user.id)
			@subject.following_users << @current_user
		else
			show_error("You are already following this subject.")
		end
		redirect_to "/subjects/#{@subject.id}"
	end
	
	def stop_following_subject
		@subject = Subject.find(params[:subject_id])
		if @subject.following_users.exists?(@current_user.id)
			@subject.following_users.delete(@current_user)
		end
		redirect_to "/subjects/#{@subject.id}"
	end
	
	private
		def same_user_check
			@message = ForumMessage.find(params[:message_id])
			if !(@current_user.id == @message.user.id || @current_user.admin)
				show_error("You are not allowed to do that.")
				redirect_to "/"
			end
		end
		
		def update_last_forum_visit
			if @current_user
				@current_user.update(last_forum_visit: Time.now)
			end
		end
		
		def new_subject_params
			params.require(:subject).permit(:title)
		end
		
		def message_params
			params.require(:forum_message).permit(:text)
		end
		
		def update_unread_subjects # Need better algorithm for this => O(nlog n) ?
			User.all.each do |u|
				u.update(unread_subjects: Subject.all.select{|s| s.forum_messages.last.created_at >= u.last_forum_visit}.count) if @current_user.id != u.id
			end
		end
		
		def clear_unread_subjects_count
			if @current_user
				@current_user.unread_subjects = 0
			end
		end
end
