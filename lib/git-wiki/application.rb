require 'fileutils'
require 'sinatra'
require 'sinatra/content_for'
require 'git-wiki/environment'
require 'git-wiki/authentication'
require 'git-wiki/gitrepo'
require 'git-wiki/page'
require 'time-ago-in-words'
require 'encrypted_cookie'
require 'sinatra/flash'

module GitWiki
  class Application < Sinatra::Base

    use Rack::Session::EncryptedCookie,
      :key => GitWiki::Environment[:cookie_key],
      :domain => GitWiki::Environment[:cookie_domain],
      :path => GitWiki::Environment[:cookie_path],
      :expire_after => GitWiki::Environment[:cookie_expire_after],
      :secret => GitWiki::Environment[:cookie_secret]

    set :app_file, __FILE__
    set :root, File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    
    enable :logging

    register Sinatra::Flash

    helpers Sinatra::ContentFor

    #
    # start of user auth (needs to be modularized now)
    #

    post '/login' do
      if GitWiki::Authentication.authenticated?(params['username'], params['password'])
        session[:username] = params['username']
        if session[:saved_path]
          redirect session[:saved_path]
        else
          redirect '/'
        end
      else
        flash[:error] = "Username or Password incorrect"
        redirect '/login'
      end
    end

    get '/login' do
      show :login, "Login"
    end
    
    get '/logout' do
      session[:username] = nil
      redirect '/'
    end

    donotsave_paths = %w{ /logout /favicon.png /favicon.ico }
    before do
      unless request.path == "/login"
        unless session[:username]
          session[:saved_path] = request.path
          session[:saved_path] = "/" if donotsave_paths.include?(request.path)
          redirect '/login'
        end
      end
    end

    #
    # end of user auth
    #

    get('/') { redirect "/page/show/#{GitWiki::Environment[:homepage]}" }
   
    #
    # page namespace
    #
    
    get '/page/show/*' do |page|
      @menu = Page.new("menu")
      @page = Page.new(page)
      @page.tracked? ? show(:show, @page.name) : redirect('/page/edit/' + @page.name)
    end
    
    get '/page/raw/*' do |page|
      @page = Page.new(page)
      send_data @page.raw_body, :type => 'text/plain', :disposition => 'inline'
    end
    
#    get '/:page/append' do
#      @page = Page.new(params[:page])
#      @page.update(@page.raw_body + "\n\n" + params[:text], params[:message])
#      redirect '/' + @page.name
#    end
    
    get '/page/edit/*' do |page|
      @menu = Page.new("menu")
      @page = Page.new(page)
      show :edit, "Editing #{@page.name}"
    end
    
    post '/page/edit/*' do |page|
      @menu = Page.new("menu")
      @page = Page.new(page)
      @page.update(params[:body], params[:message])
      redirect '/page/show/' + @page.name
    end
    
    post '/page/eip/*' do |page|
      @page = Page.new(page)
      @page.update(params[:body])
      @page.body
    end
    
    get '/page/history/*' do |page|
      @menu = Page.new("menu")
      @page = Page.new(page)
      show :history, "History of #{@page.name}"
    end
    
    get '/page/commit/*' do |splat|
      splat =~ /(.*)\/(.*)/
      page, rev = $1, $2
      @menu = Page.new("menu")
      @page = Page.new(page, rev)
      show :show, "#{@page.name} (version #{rev})"
    end
    
    get '/page/diff/*' do |splat|
      splat =~ /(.*)\/(.*)/
      page, rev = $1, $2
      @page = Page.new(page, rev)
      show :delta, "Diff of #{@page.name}"
    end
    
    get '/page/patch/*' do |splat|
      splat =~ /(.*)\/(.*)/
      page, rev = $1, $2
      @page = Page.new(page, rev)
      content_type 'text/x-diff'
      headers 'Content-Disposition' => "filename=wiki-#{page.gsub(/\//,'_')}-#{@rev}.diff"
      @page.delta
    end
   
    #
    # repo namespace
    #

    get '/repo/list' do
      pages = repo.ls_files.keys.map { |p| p.sub(/#{GitWiki::Environment[:extension]}$/, "") }
      @menu = Page.new("menu")
      @pages = pages.select { |f,bl| f[0,1] != '_'}.sort.map { |name, blob| Page.new(name) } rescue []
      show(:list, 'Listing pages')
    end
    
    get '/repo/tarball' do
      archive = repo.archive('HEAD', nil, :format => 'tgz', :prefix => 'wiki/')
      send_file archive,
        :type => 'application/x-gzip',
        :disposition => 'filename=wiki-archive.tgz'
    end
    
    get '/repo/branches' do
      @menu = Page.new("menu")
      @branches = repo.branches
      show :branches, "Branches List"
    end
    
    get '/repo/branch/:branch' do
      repo.checkout(params[:branch])
      redirect '/page/show/' + GitWiki::Environment[:homepage]
    end
    
    get '/repo/history' do
      @menu = Page.new("menu")
      @history = repo.log
      show :branch_history, "Branch History"
    end
    
    get '/repo/revert_branch/:sha' do
      repo.with_temp_index do
        repo.read_tree params[:sha]
        repo.checkout_index
        repo.commit('reverted branch')
        repo.push(repo.remote(GitWiki::Environment[:git_remote])) unless GitWiki::Environment[:git_remote].nil?
      end
      redirect '/repo/history'
    end
    
    get '/repo/merge_branch/:branch' do
      repo.merge(params[:branch])
      redirect '/page/show/' + GitWiki::Environment[:homepage]
    end
    
    get '/repo/delete_branch/:branch' do
      repo.branch(params[:branch]).delete
      redirect '/repo/branches'
    end
    
    post '/repo/new_branch' do
      repo.branch(params[:branch]).create
      repo.checkout(params[:branch])
      if params[:type] == 'blank'
        # clear out the branch
        repo.chdir do
          Dir.glob("*").each do |f|
            File.unlink(f)
            repo.remove(f)
          end
          touchfile
          repo.commit('clean branch start')
          repo.push(repo.remote(GitWiki::Environment[:git_remote])) unless GitWiki::Environment[:git_remote].nil?
        end
      end
      redirect '/repo/branches'
    end
    
    post '/repo/new_remote' do
      repo.add_remote(params[:branch_name], params[:branch_url])
      repo.fetch(params[:branch_name])
      redirect '/repo/branches'
    end
   
    #
    # search namespace
    #

    get '/search' do
      @menu = Page.new("menu")
      @search = params[:search]
      @titles = search_on_filename(@search)
      @grep = repo.grep(@search, nil, :ignore_case => true)
      [@titles, @grep].each do |x|
        puts x.inspect
        x.values.each {|v| v.each { |w| w.last.gsub!(@search, "<mark>#{escape_html @search}</mark>") } }
      end
      show :search, 'Search Results'
    end
    
    # file upload attachments
    
    get '/a/file/upload/:page' do
      @page = Page.new(params[:page])
      show :attach, 'Attach File for ' + @page.name
    end
    
    post '/a/file/upload/:page' do
      @page = Page.new(params[:page])
      @page.save_file(params[:file], params[:name])
      redirect '/page/edit/' + @page.name
    end
    
    get '/a/file/delete/:page/:file.:ext' do
      @page = Page.new(params[:page])
      @page.delete_file(params[:file] + '.' + params[:ext])
      redirect '/page/edit/' + @page.name
    end
    
    get '/_attachment/:page/:file.:ext' do
      @page = Page.new(params[:page])
      send_file(File.join(@page.attach_dir, params[:file] + '.' + params[:ext]))
    end
    
    # support methods
    def search_on_filename(search)
      needle = search.as_wiki_link
      pagenames = repo.log.first.gtree.children.keys # our haystack
      titles = {}
      pagenames.each do |page|
        next unless page.include? needle
        current_branch_sha1 = repo.log.first
        # unfreeze the String page by creating a "new" one
        titles["#{current_branch_sha1}:#{page}"] = [[0, "#{page}"]] 
      end
      titles
    end
    
    # returns an absolute url
    def page_url(page)
      "#{request.env["rack.url_scheme"]}://#{request.env["HTTP_HOST"]}/page/show/#{page}"
    end
    
    private
    
    def show(template, title)
      @title = title
      erb(template)
    end
    
    def touchfile
      # adds meta file to repo so we have somthing to commit initially
      repo.chdir do
        f = File.new(".meta",  "w+")
        f.puts(repo.current_branch)
        f.close
        repo.add('.meta')
      end
    end

    def repo
      GitWiki::GitRepo.gitwiki_instance
    end
    
  end
end

