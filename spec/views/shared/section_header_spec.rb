require "rails_helper"

RSpec.describe "shared/section_header", type: :view do
  it "renders the title as a display heading" do
    render inline: '<%= render "shared/section_header", title: "My Pets" %>'

    assert_select "h1[class~='font-display'][class~='font-bold']", text: "My Pets"
  end

  it "renders a one-sentence explanation under the title" do
    render inline: '<%= render "shared/section_header", title: "My Pets", subtitle: "Pets you\'ve published." %>'

    assert_select "h1", text: "My Pets"
    assert_select "p[class~='text-neutral-500']", text: "Pets you've published."
  end

  it "omits the explanation paragraph when no subtitle is given" do
    render inline: '<%= render "shared/section_header", title: "My Pets" %>'

    assert_select "p", false
  end

  it "renders the optional CTA slot when a block is passed" do
    render inline: <<~ERB
      <%= render "shared/section_header", title: "My Pets", subtitle: "Add a new pet." do %>
        <a class="cta-link" href="/pets/new">Publish a Pet</a>
      <% end %>
    ERB

    assert_select "a.cta-link[href='/pets/new']", text: "Publish a Pet"
  end

  it "does not render an empty CTA container when no block is given" do
    render inline: '<%= render "shared/section_header", title: "My Pets" %>'

    assert_select "header > div", count: 1
  end

  it "adds a top margin so the section explanation clears the navbar" do
    render inline: '<%= render "shared/section_header", title: "My Pets" %>'

    assert_select "header[class~='mt-6']"
  end

  it "supports a centered hero variant with a larger title" do
    render inline: '<%= render "shared/section_header", title: "Find Your Match", subtitle: "Browse pets near you.", centered: true %>'

    assert_select "header[class~='text-center'][class~='mb-8'][class~='mt-8']"
    assert_select "h1[class~='text-3xl'][class~='md:text-4xl']", text: "Find Your Match"
    assert_select "p[class~='mx-auto'][class~='text-lg']", text: "Browse pets near you."
  end

  it "respects custom header/subtitle classes" do
    render inline: '<%= render "shared/section_header", title: "T", subtitle: "S", header_class: "custom-header", subtitle_class: "custom-subtitle" %>'

    assert_select "header.custom-header"
    assert_select "p.custom-subtitle", text: "S"
  end
end
