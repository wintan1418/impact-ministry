# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "px-4 py-16 md:py-24 max-w-5xl m-auto" do
      h1 "IMPACT Ministry", class: "text-4xl font-serif tracking-tight text-gray-900 dark:text-gray-100"
      para "Daily devotionals, podcast, prayer, and giving — content desk.",
           class: "mt-3 text-lg text-gray-600 dark:text-gray-400"

      div class: "mt-12 grid grid-cols-1 md:grid-cols-3 gap-6" do
        # Cards populate as models come online (Phase 1.A onward).

        div class: "rounded-2xl border border-gray-200 dark:border-gray-700 p-6" do
          para "Today", class: "uppercase tracking-widest text-xs text-gray-500"
          para "Devotionals", class: "text-2xl font-semibold mt-2 text-gray-900 dark:text-gray-100"
          para "Scheduled, drafted, published — coming in Phase 1.A.",
               class: "mt-2 text-sm text-gray-600 dark:text-gray-400"
        end

        div class: "rounded-2xl border border-gray-200 dark:border-gray-700 p-6" do
          para "Audience", class: "uppercase tracking-widest text-xs text-gray-500"
          para "Email subscribers", class: "text-2xl font-semibold mt-2 text-gray-900 dark:text-gray-100"
          para "Capture, welcome, unsubscribe — coming in Phase 1.B.",
               class: "mt-2 text-sm text-gray-600 dark:text-gray-400"
        end

        div class: "rounded-2xl border border-gray-200 dark:border-gray-700 p-6" do
          para "Community", class: "uppercase tracking-widest text-xs text-gray-500"
          para "Prayer & testimony", class: "text-2xl font-semibold mt-2 text-gray-900 dark:text-gray-100"
          para "Moderation queues — coming in Phase 2.",
               class: "mt-2 text-sm text-gray-600 dark:text-gray-400"
        end
      end
    end
  end
end
