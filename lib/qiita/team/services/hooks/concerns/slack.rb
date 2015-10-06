require "active_support/concern"
require "slacken"

require "qiita/team/services/hooks/concerns/http_client"

module Qiita::Team::Services
  module Hooks
    module Concerns
      # Send richly-formatted messages to Slack.
      # Override {HttpClient#url} to implement HttpClient.
      #
      # @see https://api.slack.com/docs/attachments
      module Slack
        extend ActiveSupport::Concern

        DEFAULT_ICON_URL = "https://cdn.qiita.com/media/qiita-team-slack-icon.png".freeze
        ICON_EMOJI_FORMAT = /\A:[^:]+:\z/

        included do
          include HttpClient

          define_property :username, default: "Qiita:Team"
          define_property :icon_emoji

          validates :username, presence: true
          validates :icon_emoji, format: { with: ICON_EMOJI_FORMAT }, allow_blank: true
        end

        class_methods do
          # @note Override {Services::Base.service_name}.
          def service_name
            "Slack"
          end
        end

        # @return [void]
        def ping
          fallback = "Test message sent from Qiita:Team"
          send_message(attachments: [fallback: fallback, pretext: fallback])
        rescue DeliveryError
          nil
        end

        # @param event [Qiita::Team::Services::Events::ItemCreated]
        # @return [void]
        # @raise [DeliveryError]
        def item_created(event)
          fallback = "#{user_link(event.user)} created a new post"
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
              author_name: "@#{event.user.id}",
              author_link: event.user.url,
              author_icon: event.user.profile_image_url,
              title: event.item.title,
              title_link: event.item.url,
              text: Slacken.translate(event.item.rendered_body),
            ],
          )
        end

        # @param event [Qiita::Team::Services::Events::ItemUpdated]
        # @return [void]
        # @raise [DeliveryError]
        def item_updated(event)
          fallback = "#{user_link(event.user)} updated #{item_link(event.item)}"
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
            ],
          )
        end

        # @param event [Qiita::Team::Services::Events::ItemBecameCoediting]
        # @return [void]
        # @raise [DeliveryError]
        def item_became_coediting(event)
          fallback = "#{user_link(event.user)} changed #{item_link(event.item)} to coedit mode"
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
            ],
          )
        end

        # @param event [Qiita::Team::Services::Events::CommentCreated]
        # @return [void]
        # @raise [DeliveryError]
        def comment_created(event)
          fallback =
            if event.item.coediting?
              "New comment on #{item_link(event.item)}"
            else
              "New comment on #{user_link(event.item.user)}'s #{item_link(event.item)}"
            end
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
              author_name: "@#{event.user.id}",
              author_link: event.user.url,
              author_icon: event.user.profile_image_url,
              text: Slacken.translate(event.comment.rendered_body),
            ],
          )
        end

        # @param event [Qiita::Team::Services::Events::MemberAdded]
        # @return [void]
        # @raise [DeliveryError]
        def team_member_added(event)
          fallback = "#{user_link(event.member)} is added to the #{team_link(event.team)} team"
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
            ],
          )
        end

        # @param event [Qiita::Team::Services::Events::ProjectCreated]
        # @return [void]
        # @raise [DeliveryError]
        def project_created(event)
          fallback = "#{user_link(event.user)} created #{project_link(event.project)} project"
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
              author_name: "@#{event.user.id}",
              author_link: event.user.url,
              author_icon: event.user.profile_image_url,
            ],
          )
        end

        # @param event [Qiita::Team::Services::Events::ProjectUpdated]
        # @return [void]
        # @raise [DeliveryError]
        def project_updated(event)
          fallback = "#{user_link(event.user)} updated #{project_link(event.project)} project"
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
              author_name: "@#{event.user.id}",
              author_link: event.user.url,
              author_icon: event.user.profile_image_url,
            ],
          )
        end

        # @param event [Qiita::Team::Services::Events::ProjectArchived]
        # @return [void]
        # @raise [DeliveryError]
        def project_archived(event)
          fallback = "#{user_link(event.user)} archived #{project_link(event.project)} project"
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
              author_name: "@#{event.user.id}",
              author_link: event.user.url,
              author_icon: event.user.profile_image_url,
            ],
          )
        end

        # @param event [Qiita::Team::Services::Events::ProjectActivated]
        # @return [void]
        # @raise [DeliveryError]
        def project_activated(event)
          fallback = "#{user_link(event.user)} activated #{project_link(event.project)} project"
          send_message(
            attachments: [
              fallback: fallback,
              pretext: fallback,
              author_name: "@#{event.user.id}",
              author_link: event.user.url,
              author_icon: event.user.profile_image_url,
            ],
          )
        end

        private

        # @param request_body [Hash]
        # @return [void]
        def send_message(request_body)
          http_post(user_hash.merge(request_body))
        end

        # @return [Hash]
        def user_hash
          if icon_emoji.blank?
            { username: username, icon_url: DEFAULT_ICON_URL }
          else
            { username: username, icon_emoji: icon_emoji }
          end
        end

        # @param user [Qiita::Team::Services::Resources::User]
        # @return [String]
        def user_link(user)
          "<#{user.url}|#{user.name}>"
        end

        # @param item [Qiita::Team::Services::Resources::Item]
        # @return [String]
        def item_link(item)
          "<#{item.url}|#{item.title}>"
        end

        # @param project [Qiita::Team::Services::Resources::Project]
        # @return [String]
        def project_link(project)
          "<#{project.url}|#{project.name}>"
        end

        # @param team [Qiita::Team::Services::Resources::Team]
        # @return [String]
        def team_link(team)
          "<#{team.url}|#{team.name}>"
        end
      end
    end
  end
end