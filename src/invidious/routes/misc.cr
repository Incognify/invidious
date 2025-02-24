module Invidious::Routes::Misc
  def self.home(env)
    preferences = env.get("preferences").as(Preferences)
    locale = LOCALES[preferences.locale]?
    user = env.get? "user"

    case preferences.default_home
    when "Popular"
      env.redirect "/feed/popular"
    when "Trending"
      env.redirect "/feed/trending"
    when "Subscriptions"
      if user
        env.redirect "/feed/subscriptions"
      else
        env.redirect "/feed/popular"
      end
    when "Playlists"
      if user
        env.redirect "/view_all_playlists"
      else
        env.redirect "/feed/popular"
      end
    else
      templated "search_homepage", navbar_search: false
    end
  end

  def self.privacy(env)
    locale = LOCALES[env.get("preferences").as(Preferences).locale]?
    templated "privacy"
  end

  def self.licenses(env)
    locale = LOCALES[env.get("preferences").as(Preferences).locale]?
    rendered "licenses"
  end

  def self.cross_instance_redirect(env)
    referer = get_referer(env)

    if !env.get("preferences").as(Preferences).automatic_instance_redirect
      return env.redirect("https://redirect.invidious.io#{referer}")
    end

    instance_url = fetch_random_instance
    env.redirect "https://#{instance_url}#{referer}"
  end
end
