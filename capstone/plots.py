import numpy as np
import pandas as pd
import plotly.graph_objects as go
import plotly_express as px


def plot_3d_data(owid_cia_df, data_to_plot, data_for_color, map_csv):
    map_df = pd.read_csv(map_csv)
    map_df['height'] = 2
    countries = [x for _, x in map_df.groupby('group', as_index=False)]

    owid_cia_df.sort_values(by=['date'], inplace=True)
    pin_markers = go.scatter3d.Marker(size=4, symbol='circle', showscale=False)

    fig = px.scatter_3d(owid_cia_df,
                        x="capital_long", y="capital_lat", z=data_to_plot,
                        color=data_for_color,
                        range_x=[-180, 180],
                        range_y=[-90, 90],
                        hover_name='location',
                        hover_data={data_to_plot: ':,.0f', 'capital_lat': False, 'capital_long': False, 'date': False},
                        animation_frame="date",
                        title='COVID-19: {data_to_plot} per country'.format(data_to_plot=data_to_plot))
    fig.update_traces(marker=pin_markers, hoverinfo='text', marker_showscale=False)
    fig.update_traces(error_z_visible=True,
                      error_z_type='percent',
                      error_z_symmetric=False,
                      error_z_value=0,
                      error_z_valueminus=100,
                      error_z_thickness=2,
                      error_z_color="#DE3163")
    fig.update_scenes(camera_eye_x=1, camera_eye_y=-2, camera_eye_z=1)
    fig.update_scenes(yaxis_showspikes=False, yaxis_title_text='Latitude')
    fig.update_scenes(xaxis_showspikes=False, xaxis_title_text='Longitude')
    fig.update_scenes(zaxis_showspikes=False, zaxis_title_text=data_to_plot)
    fig.update_scenes(aspectratio_x=2, aspectratio_y=2, aspectratio_z=0.5)
    for country in countries:
        fig.add_scatter3d(x=country.long, y=country.lat, z=country.height,
                          hoverinfo='skip',
                          mode='lines',
                          showlegend=False,
                          line_color='#000000')

    return fig.to_html(auto_play=False, full_html=False)

