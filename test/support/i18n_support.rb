# frozen_string_literal: true

module I18nSupport
  def setup
    super
    @are_translations_mocked = false
  end

  def teardown
    I18n.backend.reload! if @are_translations_mocked
    super
  end

  def mock_translation(key, value, locale: I18n.locale)
    @are_translations_mocked = true

    nested = key.to_s.split(".").reverse.inject(value) { |acc, part| { part => acc } }
    I18n.backend.store_translations(locale, nested)
  end
end
