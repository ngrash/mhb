#!/usr/bin/env ruby

if ARGV.length < 1
	puts "Usage: ./parse.rb FILENAME"
	exit 1
end

require 'json'

IGNORE_LINES=[/Seite \d+ von \d+/, /Technische Universität Braunschweig | Modulhandbuch: .+/]

SECTIONS=[
	["Modulbezeichnung", "Modulnummer"], 
	["Institution", "Modulabkürzung"], 
	"Workload", 
	"Präsenzzeit", 
	"Semester", 
	"Leistungspunkte", 
	"Selbststudium", 
	"Anzahl Semester", 
	"Pflichtform", 
	"SWS", 
	"Lehrveranstaltungen/Oberthemen", 
	"Belegungslogik (wenn alternative Auswahl, etc.)", 
	"Lehrende", 
	"Qualifikationsziele", 
	"Inhalte",
	"Lernformen", 
	"Prüfungsmodalitäten / Voraussetzungen zur Vergabe von Leistungspunkten", 
	"Turnus (Beginn)", 
	"Modulverantwortliche(r)", 
	"Sprache", 
	"Medienformen", 
	"Literatur", 
	"Erklärender Kommentar", 
	"Kategorien (Modulgruppen)", 
	"Voraussetzungen für dieses Modul", 
	"Studiengänge", 
	"Kommentar für Zuordnung"
]

SECTION_TO_KEY={
	"Modulbezeichnung" => :mod,
	"Modulnummer" => :no,
	"Institution" => :inst,
       	"Modulabkürzung" => :short, 
	"Workload" => :total_time, 
	"Präsenzzeit" => :presence_time, 
	"Semester" => :semester,
	"Leistungspunkte" => :credit_points,
	"Selbststudium" => :self_study_time,
	"Anzahl Semester" => :semester_count,
	"Pflichtform" => :required,
	"SWS" => :hours_per_week,
	"Lehrveranstaltungen/Oberthemen" => :events,
	"Belegungslogik (wenn alternative Auswahl, etc.)" => :logic,
	"Lehrende" => :lecturer,
	"Qualifikationsziele" => :goals,
	"Inhalte" => :content,
	"Lernformen" => :pattern,
	"Prüfungsmodalitäten / Voraussetzungen zur Vergabe von Leistungspunkten" => :credit_points_requirements,
	"Turnus (Beginn)" => :rotation_begin,
	"Modulverantwortliche(r)" => :person_in_charge,
	"Sprache" => :language,
	"Medienformen" => :media,
	"Literatur" => :literature,
	"Erklärender Kommentar" => :comment,
	"Kategorien (Modulgruppen)" => :categories,
	"Voraussetzungen für dieses Modul" => :requirements,
	"Studiengänge" => :paths,
	"Kommentar für Zuordnung" => :relation_comment
}

def main
	modules = []
	File.open(ARGV[0]) do |file|
		read_until(file, get_section_at(0))

		while not file.eof? do

			mod = {}
			modules << mod
			SECTIONS.each_with_index do |section_or_array, index|
				if section_or_array.kind_of?(Array)
					last_subsection = section_or_array.last
					read_until(file, last_subsection)

					next_section = get_next_section(index)
					subsection_content = read_until(file, next_section)

					values = subsection_content.split("\n").reject { |l| l.strip.empty? }

					section_or_array.each_with_index do |subsection, index|
						mod[SECTION_TO_KEY[subsection]] = values[index]
					end
				else
					next_section = get_next_section(index)
					content = read_until(file, next_section)

					mod[SECTION_TO_KEY[section_or_array]] = content.strip
				end
			end
		end
	end

	puts JSON.generate(modules)
end

def read_until(file, section)
	text = ""
	loop do
		line = file.gets
		if section.nil?
			return text if line.start_with?("\f")
		else
			return text if line.end_with?("#{section}:\n")
		end
		text += line unless IGNORE_LINES.any? { |i| line.match?(i) }
	end
end

def get_next_section(index)
	return nil if index >= SECTIONS.length
	get_section_at(index+1)
end

def get_section_at(index)
	get_section(SECTIONS[index])
end

def get_section(section_or_array) 
	if section_or_array.kind_of?(Array)
		section_or_array[0]	
	else
		section_or_array
	end
end

main
