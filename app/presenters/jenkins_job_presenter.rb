class JenkinsJobPresenter < SimpleDelegator

  attr_reader :jenkins_job

  def initialize(jenkins_job, template)
    super(template)
    @jenkins_job = jenkins_job
  end


  def job_id
    jenkins_job.job_id
  end


  def job_info
    longdesc = l(:label_see_jenkins_job) + jenkins_job.name
    link_to_job = link_to(jenkins_job.name, jenkins_job.url, target: '_blank', alt: longdesc, longdesc: longdesc, title: longdesc)

    s = ''
    s << content_tag(:h3, link_to_job)
    s << render_job_description unless jenkins_job.project.jenkins_setting.show_compact?
    s.html_safe
  end


  def latest_build_infos
    content_tag(:ul, render_latest_build_infos, class: 'list-unstyled', style: "line-height:34px")
  end

  def render_sonarqube_report
    if (!('' == jenkins_job.sonarqube_dashboard_url))
      return content_tag(:span, link_to_sonarqube_dashboard_url(jenkins_job.sonarqube_dashboard_url).html_safe)
    else
      return content_tag(:span, l(:label_no_sonarqube_report_available))
    end
  end

  def latest_changesets
    changesets = jenkins_job.builds.last.changesets rescue []
    return '' if changesets.empty?
    content_tag(:ul, render_changesets_list(changesets), class: 'changesets_list list-unstyled')
  end


  def build_history
    s = content_tag(:ul, build_history_list, class: 'list-unstyled')
    s.html_safe
  end


  def job_actions
    s = content_tag(:ul, job_actions_list, class: 'list-unstyled', style: "line-height:34px")
    s.html_safe
  end


  private

    def render_latest_build_infos
      s = ''
      s << content_tag(:li, render_jenkins_job_latest_build_link_and_state(jenkins_job))

      s << content_tag(:li, latest_build_duration) 
      s << content_tag(:li, latest_build_date) 

      # s << content_tag(:li, link_to_console_output)
      s << content_tag(:li, '', class: 'icon icon-running') if jenkins_job.state == 'running'

      s.html_safe
    end


    def render_jenkins_job_latest_build_link_and_state(jenkins_job)
      img_desc = l(:label_job_build_state) + ": " + state_to_label(jenkins_job.state) + " (" + jenkins_job.state_color + ")"

      s = ''
      s << content_tag(:span, link_to_jenkins_job_latest_build(jenkins_job).html_safe, class: 'label label-info')
      s << content_tag(:span, state_color_to_image(jenkins_job.state_color, img_desc), class: 'job_status_line')
      s << content_tag(:span, link_to_jenkins_job_latest_build_console(jenkins_job).html_safe, class: 'job_status_line')

      s.html_safe
    end


    def latest_build_duration
      s = ''
      s << l(:label_job_duration)
      s << ': '
      s << Time.at(jenkins_job.latest_build_duration/1000).strftime("%M:%S") rescue "00:00"
      s.html_safe
    end

    def job_actions_list
      s = ''
      s << content_tag(:li, link_to_refresh, style: getLiStyleForIcons)
      if User.current.allowed_to?(:build_jenkins_jobs, jenkins_job.project)
        s << content_tag(:li, link_to_build, style: getLiStyleForIcons)
      end
      s.html_safe
    end

    def getLiStyleForIcons
      "line-height:34px; margin:2px; vertical-align:middle; "
    end

    def render_job_description
      s = ''
      s << jenkins_job.description
      s
    end


    def build_history_list
      s = ''
      
      if jenkins_job.health_report.any?
        jenkins_job.health_report.each do |health_report|
          s << content_tag(:li, render_health_report_element(health_report), style: getLiStyleForIcons)
        end
      end
  
      s << content_tag(:li, link_to_history, style: getLiStyleForIcons)
      s.html_safe
    end
  

    def render_health_report_element(health_report)
      "#{weather_icon(health_report['iconUrl'], health_report['description'])}".html_safe
    end

    def latest_build_date
      l(:label_finished_at) + ": #{format_time(jenkins_job.latest_build_date)}"
    end


    def link_to_console_output
      # url = jenkins_job.latest_build_number == 0 ? 'javascript:void(0);' : console_jenkins_job_path(jenkins_job.project, jenkins_job)
      # link_to(l(:label_see_console_output), url, class: 'modal-box-close-only')
      # title: l(:label_see_console_output), remote: true, target:'_blank'

    end


    def link_to_build
      link_to(fa_icon('fa-gears'), build_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_build_now), remote: true)
    end


    def link_to_refresh
      link_to(fa_icon('fa-refresh'), refresh_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_refresh_builds), remote: true)
    end


    def link_to_history
      jenkins_history_url = history_jenkins_job_path(jenkins_job.project, jenkins_job)
      jenkins_history_title = l(:label_see_jenkins_jobs_history)
      # modal_box_css_class = 'fa fa-lg fa-history modal-box-close-only'
      modal_box_css_class = 'modal-box-close-only'

      # icon_image = content_tag(:span, url_title, class: "fa fa-lg fa-history").html_safe
      # icon_image = fa_icon 'fa-history', text: "Jenkins Jobs\' History" 
      # link_to(icon_image, jenkins_history_url, class: 'modal-box-close-only', title: url_title)
      # , data: { "toggle" => "tooltip", "original-title" => "History", "title" => "History"} 
      # class: 'modal-box-close-only', data: { "toggle" => "tooltip", "original-title" => "Logout", "placement" => "bottom" }
      # data: {toggle: "modal", target: "#modal"} 
      # :data => { "toggle" => "tooltip", "original-title" => "Logout"},
      link_to(jenkins_history_title, jenkins_history_url, class: modal_box_css_class, title: jenkins_history_title)
    end


    def render_changesets_list(changesets)
      visible_changesets = changesets.take(5)
      invisible_changesets = changesets - visible_changesets
      render_visible_changesets(visible_changesets) + render_invisible_changesets(invisible_changesets)
    end


    def render_visible_changesets(changesets)
      render_changesets(changesets, visible: true)
    end


    def render_invisible_changesets(changesets)
      render_display_more + render_changesets(changesets, visible: false) if !changesets.empty?
    end


    def render_changesets(changesets, opts = {})
      visible = opts.delete(:visible){ true }
      css_class = visible ? 'changesets visible' : 'changesets invisible'
      id = visible ? "changesets-visible-#{jenkins_job.id}" : "changesets-invisible-#{jenkins_job.id}"

      s = ''
      changesets.each do |changeset|
        s << content_tag(:li, content_for_changeset(changeset).html_safe)
      end

      content_tag(:div, s.html_safe, class: css_class, id: id)
    end


    def render_display_more
      link_to l(:label_display_more), '#', onclick: "$('#changesets-invisible-#{jenkins_job.id}').toggle(); return false;"
    end


    def content_for_changeset(changeset)
      s = ''
      s << content_tag(:p, link_to("##{changeset.revision[0..10]}", changeset_url(changeset)), class: 'revision')
      s << textilizable(changeset, :comments)
      s
    end


    def changeset_url(changeset)
      if !jenkins_job.repository.nil?
        { controller: 'repositories', action: 'revision', id: jenkins_job.project, repository_id: jenkins_job.repository.identifier_param, rev: changeset.revision }
      else
        '#'
      end
    end

end
