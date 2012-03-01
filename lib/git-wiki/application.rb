require 'fileutils'
require 'sinatra'
require 'sinatra/content_for'
require 'git-wiki/environment'
require 'git-wiki/config'
require 'git-wiki/authentication'
require 'time-ago-in-words'
require 'encrypted_cookie'
require 'sinatra/flash'

module GitWiki
  class Application < Sinatra::Base

    use Rack::Session::EncryptedCookie,
      :key => GitWiki::Config[:cookie_key],
      :domain => GitWiki::Config[:cookie_domain],
      :path => GitWiki::Config[:cookie_path],
      :expire_after => GitWiki::Config[:cookie_expire_after],
      :secret => GitWiki::Config[:cookie_secret]

    set :app_file, __FILE__
    set :root, File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

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

    before do
      unless request.path == "/login"
        unless session[:username]
          session[:saved_path] = request.path
          redirect '/login'
        end
      end
    end

    #
    # end of user auth
    #

    get('/') { redirect "/#{HOMEPAGE}" }
    
    # page paths
    
    get '/:page' do
      @menu = Page.new("menu")
      @page = Page.new(params[:page])
      @page.tracked? ? show(:show, @page.name) : redirect('/e/' + @page.name)
    end
    
    get '/:page/raw' do
      @page = Page.new(params[:page])
      send_data @page.raw_body, :type => 'text/plain', :disposition => 'inline'
    end
    
    get '/:page/append' do
      @page = Page.new(params[:page])
      @page.update(@page.raw_body + "\n\n" + params[:text], params[:message])
      redirect '/' + @page.name
    end
    
    get '/e/:page' do
      @menu = Page.new("menu")
      @page = Page.new(params[:page])
      show :edit, "Editing #{@page.name}"
    end
    
    post '/e/:page' do
      @menu = Page.new("menu")
      @page = Page.new(params[:page])
      @page.update(params[:body], params[:message])
      redirect '/' + @page.name
    end
    
    post '/eip/:page' do
      @page = Page.new(params[:page])
      @page.update(params[:body])
      @page.body
    end
    
    get '/h/:page' do
      @menu = Page.new("menu")
      @page = Page.new(params[:page])
      show :history, "History of #{@page.name}"
    end
    
    get '/h/:page/:rev' do
      @menu = Page.new("menu")
      @page = Page.new(params[:page], params[:rev])
      show :show, "#{@page.name} (version #{params[:rev]})"
    end
    
    get '/d/:page/:rev' do
      @page = Page.new(params[:page])
      show :delta, "Diff of #{@page.name}"
    end
    
    # application paths (/a/ namespace)
    
    get '/a/list' do
      pages = $repo.log.first.gtree.children
      @menu = Page.new("menu")
      @pages = pages.select { |f,bl| f[0,1] != '_'}.sort.map { |name, blob| Page.new(name) } rescue []
      show(:list, 'Listing pages')
    end
    
    get '/a/patch/:page/:rev' do
      @page = Page.new(params[:page])
      header 'Content-Type' => 'text/x-diff'
      header 'Content-Disposition' => 'filename=patch.diff'
      @page.delta(params[:rev])
    end
    
    get '/a/tarball' do
      header 'Content-Type' => 'application/x-gzip'
      header 'Content-Disposition' => 'filename=archive.tgz'
      archive = $repo.archive('HEAD', nil, :format => 'tgz', :prefix => 'wiki/')
      File.open(archive).read
    end
    
    get '/a/branches' do
      @menu = Page.new("menu")
      @branches = $repo.branches
      show :branches, "Branches List"
    end
    
    get '/a/branch/:branch' do
      $repo.checkout(params[:branch])
      redirect '/' + HOMEPAGE
    end
    
    get '/a/history' do
      @menu = Page.new("menu")
      @history = $repo.log
      show :branch_history, "Branch History"
    end
    
    get '/a/revert_branch/:sha' do
      $repo.with_temp_index do
        $repo.read_tree params[:sha]
        $repo.checkout_index
        $repo.commit('reverted branch')
      end
      redirect '/a/history'
    end
    
    get '/a/merge_branch/:branch' do
      $repo.merge(params[:branch])
      redirect '/' + HOMEPAGE
    end
    
    get '/a/delete_branch/:branch' do
      $repo.branch(params[:branch]).delete
      redirect '/a/branches'
    end
    
    post '/a/new_branch' do
      $repo.branch(params[:branch]).create
      $repo.checkout(params[:branch])
      if params[:type] == 'blank'
        # clear out the branch
        $repo.chdir do
          Dir.glob("*").each do |f|
            File.unlink(f)
            $repo.remove(f)
          end
          touchfile
          $repo.commit('clean branch start')
        end
      end
      redirect '/a/branches'
    end
    
    post '/a/new_remote' do
      $repo.add_remote(params[:branch_name], params[:branch_url])
      $repo.fetch(params[:branch_name])
      redirect '/a/branches'
    end
    
    get '/a/search' do
      @menu = Page.new("menu")
      @search = params[:search]
      @titles = search_on_filename(@search)
      @grep = $repo.grep(@search, nil, :ignore_case => true)
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
      redirect '/e/' + @page.name
    end
    
    get '/a/file/delete/:page/:file.:ext' do
      @page = Page.new(params[:page])
      @page.delete_file(params[:file] + '.' + params[:ext])
      redirect '/e/' + @page.name
    end
    
    get '/_attachment/:page/:file.:ext' do
      @page = Page.new(params[:page])
      send_file(File.join(@page.attach_dir, params[:file] + '.' + params[:ext]))
    end
    
    # support methods
    def search_on_filename(search)
      needle = search.as_wiki_link
      pagenames = $repo.log.first.gtree.children.keys # our haystack
      titles = {}
      pagenames.each do |page|
        next unless page.include? needle
        current_branch_sha1 = $repo.log.first
        titles["#{current_branch_sha1}:#{page}"] = page.map {|page| [0, page] }
      end
      titles
    end
    
    # returns an absolute url
    def page_url(page)
      "#{request.env["rack.url_scheme"]}://#{request.env["HTTP_HOST"]}/#{page}"
    end
    
    private
    
    def show(template, title)
      @title = title
      erb(template)
    end
    
    def touchfile
      # adds meta file to repo so we have somthing to commit initially
      $repo.chdir do
        f = File.new(".meta",  "w+")
        f.puts($repo.current_branch)
        f.close
        $repo.add('.meta')
      end
    end

  end
end

