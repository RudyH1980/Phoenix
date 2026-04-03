defmodule PhoenixAnalyticsWeb.Live.Dashboard.EditSiteLive do
  use PhoenixAnalyticsWeb, :live_view

  alias PhoenixAnalytics.Analytics

  @impl true
  def mount(%{"site_id" => site_id}, _session, socket) do
    case Ash.get(Analytics.Site, site_id) do
      {:ok, site} when not is_nil(site) ->
        if site.org_id in socket.assigns.current_org_ids do
          {:ok,
           assign(socket,
             site: site,
             name: site.name,
             domain: site.domain,
             active: site.active,
             tags: site.tags || [],
             preset_tags: ~w(Prod Test Staging),
             custom_tag: "",
             saved: false,
             page_title: "Bewerk #{site.name}"
           )}
        else
          {:ok,
           socket
           |> put_flash(:error, "Geen toegang.")
           |> push_navigate(to: ~p"/dashboard")}
        end

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Website niet gevonden.")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_event("toggle_preset_tag", %{"tag" => tag}, socket) do
    tags =
      if tag in socket.assigns.tags do
        List.delete(socket.assigns.tags, tag)
      else
        [tag | socket.assigns.tags]
      end

    {:noreply, assign(socket, tags: tags, saved: false)}
  end

  def handle_event("add_custom_tag", %{"tag" => tag}, socket) do
    tag = String.trim(tag)

    tags =
      if tag != "" and tag not in socket.assigns.tags do
        socket.assigns.tags ++ [tag]
      else
        socket.assigns.tags
      end

    {:noreply, assign(socket, tags: tags, custom_tag: "", saved: false)}
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    {:noreply, assign(socket, tags: List.delete(socket.assigns.tags, tag), saved: false)}
  end

  def handle_event("save", %{"name" => name, "domain" => domain, "active" => active}, socket) do
    do_save(socket, name, domain, active == "true")
  end

  def handle_event("save", %{"name" => name, "domain" => domain}, socket) do
    do_save(socket, name, domain, false)
  end

  defp do_save(socket, name, domain, active) do
    case socket.assigns.site
         |> Ash.Changeset.for_update(:update, %{
           name: name,
           domain: domain,
           active: active,
           tags: socket.assigns.tags
         })
         |> Ash.update() do
      {:ok, site} ->
        {:noreply,
         assign(socket, site: site, name: name, domain: domain, active: active, saved: true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Opslaan mislukt.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pa-container">
      <nav class="pa-breadcrumb">
        <.link navigate={~p"/dashboard"}>Dashboard</.link>
        / <.link navigate={~p"/dashboard/sites/#{@site.id}"}>{@site.name}</.link>
        / <strong>Bewerken</strong>
      </nav>

      <div class="pa-page-header">
        <h2>Website bewerken</h2>
      </div>

      <%= if @saved do %>
        <div class="pa-flash pa-flash--success">Wijzigingen opgeslagen.</div>
      <% end %>

      <.form for={%{}} phx-submit="save" class="pa-form">
        <div class="pa-field">
          <label for="name">Naam</label>
          <input type="text" id="name" name="name" value={@name} required />
        </div>

        <div class="pa-field">
          <label for="domain">Domein</label>
          <input type="text" id="domain" name="domain" value={@domain} required />
          <span class="pa-hint">Zonder https:// of www</span>
        </div>

        <div class="pa-field">
          <label>Tags</label>
          <div style="display:flex; gap:0.5rem; flex-wrap:wrap; margin-bottom:0.75rem;">
            <%= for tag <- @preset_tags do %>
              <button
                type="button"
                phx-click="toggle_preset_tag"
                phx-value-tag={tag}
                class={"pa-tag-btn#{if tag in @tags, do: " active"}"}
              >
                {tag_icon(tag)} {tag}
              </button>
            <% end %>
          </div>

          <%= if not Enum.empty?(@tags) do %>
            <div style="display:flex; gap:0.5rem; flex-wrap:wrap; margin-bottom:0.75rem;">
              <%= for tag <- @tags do %>
                <span class={"pa-tag pa-tag--#{tag_color(tag)}"}>
                  {tag}
                  <button
                    type="button"
                    phx-click="remove_tag"
                    phx-value-tag={tag}
                    style="background:none;border:none;cursor:pointer;padding:0 0 0 4px;color:inherit;font-size:0.8rem;"
                  >
                    ✕
                  </button>
                </span>
              <% end %>
            </div>
          <% end %>

          <div style="display:flex; gap:0.5rem; align-items:center;">
            <input
              type="text"
              placeholder="Eigen tag toevoegen..."
              value={@custom_tag}
              id="custom-tag-input"
              style="flex:1; max-width:220px;"
              phx-keydown="add_custom_tag"
              phx-key="Enter"
              name="_custom_tag_input"
              phx-value-tag={@custom_tag}
            />
            <button
              type="button"
              class="pa-btn pa-btn--ghost"
              style="padding: 0.4rem 0.75rem;"
              phx-click={JS.dispatch("keydown", to: "#custom-tag-input", detail: %{key: "Enter"})}
            >
              +
            </button>
          </div>
          <span class="pa-hint">Druk Enter om toe te voegen</span>
        </div>

        <div class="pa-field">
          <label style="display:flex; align-items:center; gap:0.5rem; cursor:pointer;">
            <input type="hidden" name="active" value="false" />
            <input
              type="checkbox"
              name="active"
              value="true"
              checked={@active}
              style="width:1rem;height:1rem;"
            /> Site actief (tracker accepteert pageviews)
          </label>
        </div>

        <div style="display:flex; gap:0.75rem; align-items:center; margin-top:1rem;">
          <button type="submit" class="pa-btn pa-btn--primary">Opslaan</button>
          <.link navigate={~p"/dashboard/sites/#{@site.id}"} class="pa-btn pa-btn--ghost">
            Annuleren
          </.link>
        </div>
      </.form>

      <div class="pa-snippet-box" style="margin-top:2rem;">
        <h3>Tracker token</h3>
        <pre class="pa-code"><code>{@site.token}</code></pre>
        <span class="pa-hint">Gebruik dit token in je data-site attribuut.</span>
      </div>
    </div>
    """
  end

  defp tag_icon("Prod"), do: "🟢"
  defp tag_icon("Test"), do: "🟡"
  defp tag_icon("Staging"), do: "🔵"
  defp tag_icon(_), do: "🏷️"

  defp tag_color("Prod"), do: "green"
  defp tag_color("Test"), do: "yellow"
  defp tag_color("Staging"), do: "blue"
  defp tag_color(_), do: "default"
end
