#!/usr/bin/env python


""""
Output a yml file with all software versions.
"""

import yaml
import platform
from textwrap import dedent


def _make_versions_html(versions):
    html = [
        dedent(
            """\
            <style>
            #nf-core-versions tbody:nth-child(even) {
                background-color: #f2f2f2;
            }
            </style>
            <table class="table" style="width:100%" id="nf-core-versions">
                <thead>
                    <tr>
                        <th> Process Name </th>
                        <th> Software </th>
                        <th> Version  </th>
                    </tr>
                </thead>
            """
        )
    ]
    for process, tmp_versions in sorted(versions.items()):
        html.append("<tbody>")
        for tool, version in sorted(tmp_versions.items()):
            html.append(
                dedent(
                    f"""\
                    <tr>
                        <td><samp>{process}</samp></td>
                        <td><samp>{tool}</samp></td>
                        <td><samp>{version}</samp></td>
                    </tr>
                    """
                )
            )
        html.append("</tbody>")
    html.append("</table>")
    return "\n".join(html)


def main():
    """Load all version files and generate merged output."""
    versions_this_module = {}
    versions_this_module["${task.process}"] = {
        "python": platform.python_version(),
        "yaml": yaml.__version__,
    }

    with open("collated_versions.yml") as f:
        versions_by_process = yaml.load(f, Loader=yaml.BaseLoader) | versions_this_module

    # Group tools by process
    versions_by_process = sorted(versions_by_process.items())

    # Dump to YAML
    with open("software_versions.yml", "w") as f:
        yaml.dump(versions_by_process, f, default_flow_style=False)

    # Dump as MultiQC YAML
    versions_mqc = {
        "id": "software_versions",
        "section_name": "${workflow.manifest.name} Software Versions",
        "section_href": "https://github.com/${workflow.manifest.name}",
        "plot_type": "html",
        "description": "are collected at run time from the software output.",
        "data": _make_versions_html(versions_by_process),
    }
    with open("software_versions_mqc.yml", "w") as f:
        yaml.dump(versions_mqc, f, default_flow_style=False)

    # Write out versions for this module
    with open("versions.yml", "w") as f:
        yaml.dump(versions_this_module, f, default_flow_style=False)


if __name__ == "__main__":
    main()
